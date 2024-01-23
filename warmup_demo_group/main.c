
/******************************************************************************
*
* Copyright (C) 2009 - 2017 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

//Standard library includes
#include <stdio.h>
#include <string.h>
#include <stdlib.h> //AKB ADDED

//BSP includes for peripherals
#include "xparameters.h"
#include "netif/xadapter.h"

#include "platform.h"
#include "platform_config.h"
#if defined (__arm__) || defined(__aarch64__)
#include "xil_printf.h"
#endif
#include "xil_cache.h"

//LWIP include files
#include "lwip/ip_addr.h"
#include "lwip/tcp.h"
#include "lwip/err.h"
#include "lwip/tcp.h"
#include "lwip/inet.h"
#include "lwip/etharp.h"
#if LWIP_IPV6==1
#include "lwip/ip.h"
#else
#if LWIP_DHCP==1
#include "lwip/dhcp.h"
#endif
#endif

//added for gpio access
#include "xgpio.h"

void lwip_init(); /* missing declaration in lwIP */
struct netif *echo_netif;

//TCP Network Params
#define SRC_MAC_ADDR {0x00, 0x0a, 0x35, 0x00, 0x01, 0x02}
#define SRC_IP4_ADDR "192.168.1.10"
#define IP4_NETMASK "255.255.255.0"
#define IP4_GATEWAY "192.168.1.1"
#define SRC_PORT 7

#define DEST_IP4_ADDR  "192.168.1.11"
#define DEST_IP6_ADDR "fe80::6600:6aff:fe71:fde6"
#define DEST_PORT 22

#define TCP_SEND_BUFSIZE 20

//Function prototypes
#if LWIP_IPV6==1
void print_ip6(char *msg, ip_addr_t *ip);
#else
void print_ip(char *msg, ip_addr_t *ip);
void print_ip_settings(ip_addr_t *ip, ip_addr_t *mask, ip_addr_t *gw);
#endif
int setup_client_conn();
void tcp_fasttmr(void);
void tcp_slowtmr(void);

//Function prototypes for callbacks
static err_t tcp_client_connected(void *arg, struct tcp_pcb *tpcb, err_t err);
static err_t tcp_client_recv(void *arg, struct tcp_pcb *tpcb, struct pbuf *p, err_t err);
static err_t tcp_client_sent(void *arg, struct tcp_pcb *tpcb, u16_t len);
static void tcp_client_err(void *arg, err_t err);
static void tcp_client_close(struct tcp_pcb *pcb);

//DHCP global variables
#if LWIP_IPV6==0
#if LWIP_DHCP==1
extern volatile int dhcp_timoutcntr;
err_t dhcp_start(struct netif *netif);
#endif
#endif

//Networking global variables
extern volatile int TcpFastTmrFlag;
extern volatile int TcpSlowTmrFlag;
static struct netif server_netif;
struct netif *app_netif;
static struct tcp_pcb *c_pcb;
char is_connected;

/* AKB ADDED START */
#define LED 0xffff
#define CHANNEL 1
//GPIO drivers
XGpio Gpio_LED_SW;
XGpio GpioBUTTONS;
//global vars
uint32_t value_send = 0;
uint32_t value_recv = 0xffffffff;
/* AKB ADDED END */

int main()
{
	//Varibales for IP parameters
#if LWIP_IPV6==0
	ip_addr_t ipaddr, netmask, gw;
#endif

	//The mac address of the board. this should be unique per board
	unsigned char mac_ethernet_address[] = SRC_MAC_ADDR;

	//Network interface
	app_netif = &server_netif;

	//Initialize platform
	init_platform();

	//Defualt IP parameter values
#if LWIP_IPV6==0
#if LWIP_DHCP==1
    ipaddr.addr = 0;
	gw.addr = 0;
	netmask.addr = 0;
#else
	(void)inet_aton(SRC_IP4_ADDR, &ipaddr);
	(void)inet_aton(IP4_NETMASK, &netmask);
	(void)inet_aton(IP4_GATEWAY, &gw);
#endif
#endif

	//LWIP initialization
	lwip_init();

	//Setup Network interface and add to netif_list
#if (LWIP_IPV6 == 0)
	if (!xemac_add(app_netif, &ipaddr, &netmask,
						&gw, mac_ethernet_address,
						PLATFORM_EMAC_BASEADDR)) {
		xil_printf("Error adding N/W interface\n");
		return -1;
	}
#else
	if (!xemac_add(app_netif, NULL, NULL, NULL, mac_ethernet_address,
						PLATFORM_EMAC_BASEADDR)) {
		xil_printf("Error adding N/W interface\n");
		return -1;
	}
	app_netif->ip6_autoconfig_enabled = 1;

	netif_create_ip6_linklocal_address(app_netif, 1);
	netif_ip6_addr_set_state(app_netif, 0, IP6_ADDR_VALID);

#endif
	netif_set_default(app_netif);

	//Now enable interrupts
	platform_enable_interrupts();

	//Specify that the network is up
	netif_set_up(app_netif);

#if (LWIP_IPV6 == 0)
#if (LWIP_DHCP==1)
	/* Create a new DHCP client for this interface.
	 * Note: you must call dhcp_fine_tmr() and dhcp_coarse_tmr() at
	 * the predefined regular intervals after starting the client.
	 */
	dhcp_start(app_netif);
	dhcp_timoutcntr = 24;

	while(((app_netif->ip_addr.addr) == 0) && (dhcp_timoutcntr > 0))
		xemacif_input(app_netif);

	if (dhcp_timoutcntr <= 0) {
		if ((app_netif->ip_addr.addr) == 0) {
			xil_printf("DHCP Timeout\n");
			xil_printf("Configuring default IP of %s\n", SRC_IP4_ADDR);
			(void)inet_aton(SRC_IP4_ADDR, &(app_netif->ip_addr));
			(void)inet_aton(IP4_NETMASK, &(app_netif->netmask));
			(void)inet_aton(IP4_GATEWAY, &(app_netif->gw));
		}
	}

	ipaddr.addr = app_netif->ip_addr.addr;
	gw.addr = app_netif->gw.addr;
	netmask.addr = app_netif->netmask.addr;
#endif
#endif

	//Print connection settings
#if (LWIP_IPV6 == 0)
	print_ip_settings(&ipaddr, &netmask, &gw);
#else
	print_ip6("Board IPv6 address ", &app_netif->ip6_addr[0].u_addr.ip6);
#endif

	//Gratuitous ARP to announce MAC/IP address to network
	etharp_gratuitous(app_netif);

	//Setup connection
	setup_client_conn();

	/*** AKB ADDED START ***/

	//setup LED and SWs
	int Status_LED_SWs = XGpio_Initialize(&Gpio_LED_SW, XPAR_AXI_GPIO_0_DEVICE_ID);
	if (Status_LED_SWs != XST_SUCCESS) {
			xil_printf("LED Gpio Initialization Failed\r\n");
			return XST_FAILURE;
	}

	XGpio_SetDataDirection(&Gpio_LED_SW, 1, 0x0000FFFF); //sets all 16 bits as input (F) [SW]
	XGpio_SetDataDirection(&Gpio_LED_SW, 2, 0x00000000); //sets all 16 bits as output (0) [LED]

	//setup switches
	//int StatusSWT = XGpio_Initialize(&GpioSWT, XPAR_AXI_GPIO_SWT_DEVICE_ID);
	//if (StatusSWT != XST_SUCCESS) {
	//			xil_printf("SWT Gpio Initialization Failed\r\n");
	//			return XST_FAILURE;
	//}
	//XGpio_SetDataDirection(&GpioSWT, CHANNEL, 0xffff); //sets all 16 bits as input (1)

	//setup BUTTONS
	int StatusBUTTONS = XGpio_Initialize(&GpioBUTTONS, XPAR_AXI_GPIO_1_DEVICE_ID);
		if (StatusBUTTONS != XST_SUCCESS) {
					xil_printf("BUTTONS Gpio Initialization Failed\r\n");
					return XST_FAILURE;
	}
	XGpio_SetDataDirection(&GpioBUTTONS, CHANNEL, 0xffff); //sets all buttons as input (1)

	/*** AKB ADDED END ***/

	u32 previous_buttons = 0x00000000;
	int button_rising_edge = 0;
	int debounce_counter = 0;

	//Event loop
	while (1) {
		//Call tcp_tmr functions
		//Must be called regularly
		if (TcpFastTmrFlag) {
			tcp_fasttmr();
			TcpFastTmrFlag = 0;
		}
		if (TcpSlowTmrFlag) {
			tcp_slowtmr();
			TcpSlowTmrFlag = 0;
		}

		//Process data queued after interupt
		xemacif_input(app_netif);

		//ADD CODE HERE to be repeated constantly
		// Note - should be non-blocking
		// Note - can check is_connected global var to see if connection open

		/*** AKB ADDED START ***/
		uint32_t buttons_state = XGpio_DiscreteRead(&GpioBUTTONS, 1);
		//DESCRIPTION	Push Buttons 5 to 0 {Down Right Left Up Center}
		//xil_printf("%08x\n", buttons_state);

		if ((buttons_state != 0x00000000) && (previous_buttons == 0x00000000) && (debounce_counter > 100000)) {
			button_rising_edge = 1;
			debounce_counter = 0;
		} else {
			button_rising_edge = 0;
		}

		previous_buttons = buttons_state;

		if ((buttons_state & 0x02) && button_rising_edge) { //BTNL
			xil_printf("ButtonL\n");
			xil_printf("Old value_send: %08x\n", value_send);
			xil_printf("SW value: %08x\n", XGpio_DiscreteRead(&Gpio_LED_SW, 1));

			value_send = (XGpio_DiscreteRead(&Gpio_LED_SW, 1) << 16) | (value_send & 0x0000ffff); //update upper 16 bits
			XGpio_DiscreteWrite(&Gpio_LED_SW, 2, (value_recv & 0xffff0000) >> 16);

			xil_printf("New value_send: %08x\n", value_send);

		}

		else if ((buttons_state & 0x04) && button_rising_edge) { //BTNR
			xil_printf("ButtonR\n");
			xil_printf("Old value_send: %08x\n", value_send);
			xil_printf("SW value: %08x\n", XGpio_DiscreteRead(&Gpio_LED_SW, 1));

			value_send = XGpio_DiscreteRead(&Gpio_LED_SW, 1) | (value_send & 0xffff0000); //update lower 16 bits
			XGpio_DiscreteWrite(&Gpio_LED_SW, 2, value_recv & 0x0000ffff);

			xil_printf("New value_send: %08x\n", value_send);
		}

		if ((buttons_state & 0x08) && button_rising_edge) { //BTNC
			xil_printf("BTNC\n");
			char send_buf[8];
			u32_t i;

			send_buf[0] = (char)(0x50);		//P
			send_buf[1] = (char)(0x4F);		//O
			send_buf[2] = (char)(0x53);		//S
			send_buf[3] = (char)(0x54);		//T

			u32 send_mask = 0xFF000000;

			for(i = 0; i < 4; i = i + 1) {
				send_buf[i + 4] = (char)((value_send >> (32 - (8 * (i+1)))));		// Every iteration, shift to right 8 more bits, and get lower 8 bits (0xFF mask)
			}

			u8_t apiflags = TCP_WRITE_FLAG_COPY | TCP_WRITE_FLAG_MORE;

			//Loop until enough room in buffer (should be right away)
			while (tcp_sndbuf(c_pcb) < sizeof(send_buf));

			err_t err = tcp_write(c_pcb, send_buf, sizeof(send_buf), apiflags);
			if (err != ERR_OK) {
				xil_printf("Error writing");
			}

			//send the data packet
			err = tcp_output(c_pcb);

			if (err != ERR_OK) {
				xil_printf("TCP client: Error on tcp_output: %d\n",err);
				return err;
			}
		}

		if ((buttons_state & 0x01) && button_rising_edge) { //BTND
			xil_printf("BTND\n");
			char send_buf[3];

			send_buf[0] = (char)(0x47);		//G
			send_buf[1] = (char)(0x45);		//E
			send_buf[2] = (char)(0x54);		//T

			//Just send a single packet
			u8_t apiflags = TCP_WRITE_FLAG_COPY | TCP_WRITE_FLAG_MORE;

			//Loop until enough room in buffer (should be right away)
			while (tcp_sndbuf(c_pcb) < sizeof(send_buf));

			err_t err = tcp_write(c_pcb, send_buf, sizeof(send_buf), apiflags);
			if (err != ERR_OK) {
				xil_printf("Error writing");
			}

			//send the data packet
			err = tcp_output(c_pcb);

			if (err != ERR_OK) {
				xil_printf("TCP client: Error on tcp_output: %d\n",err);
				return err;
			}
		}

		debounce_counter += 1;
		//xil_printf("TIME!!\n");
		//xil_printf("is_connected status: %d\n", is_connected);
		/*** AKB ADDED END ***/
	}

	//Never reached
	cleanup_platform();

	return 0;
}


#if LWIP_IPV6==1
void print_ip6(char *msg, ip_addr_t *ip)
{
	print(msg);
	xil_printf(" %x:%x:%x:%x:%x:%x:%x:%x\n",
			IP6_ADDR_BLOCK1(&ip->u_addr.ip6),
			IP6_ADDR_BLOCK2(&ip->u_addr.ip6),
			IP6_ADDR_BLOCK3(&ip->u_addr.ip6),
			IP6_ADDR_BLOCK4(&ip->u_addr.ip6),
			IP6_ADDR_BLOCK5(&ip->u_addr.ip6),
			IP6_ADDR_BLOCK6(&ip->u_addr.ip6),
			IP6_ADDR_BLOCK7(&ip->u_addr.ip6),
			IP6_ADDR_BLOCK8(&ip->u_addr.ip6));

}
#else
void print_ip(char *msg, ip_addr_t *ip)
{
	print(msg);
	xil_printf("%d.%d.%d.%d\n", ip4_addr1(ip), ip4_addr2(ip),
			ip4_addr3(ip), ip4_addr4(ip));
}

void print_ip_settings(ip_addr_t *ip, ip_addr_t *mask, ip_addr_t *gw)
{

	print_ip("Board IP: ", ip);
	print_ip("Netmask : ", mask);
	print_ip("Gateway : ", gw);
}
#endif


int setup_client_conn()
{
	struct tcp_pcb *pcb;
	err_t err;
	ip_addr_t remote_addr;

	xil_printf("Setting up client connection\n");

#if LWIP_IPV6==1
	remote_addr.type = IPADDR_TYPE_V6;
	err = inet6_aton(DEST_IP6_ADDR, &remote_addr);
#else
	err = inet_aton(DEST_IP4_ADDR, &remote_addr);
#endif

	if (!err) {
		xil_printf("Invalid Server IP address: %d\n", err);
		return -1;
	}

	//Create new TCP PCB structure
	pcb = tcp_new_ip_type(IPADDR_TYPE_ANY);
	if (!pcb) {
		xil_printf("Error creating PCB. Out of Memory\n");
		return -1;
	}

	//Bind to specified @port
	err = tcp_bind(pcb, IP_ANY_TYPE, SRC_PORT);
	if (err != ERR_OK) {
		xil_printf("Unable to bind to port %d: err = %d\n", SRC_PORT, err);
		return -2;
	}

	//Connect to remote server (with callback on connection established)
	err = tcp_connect(pcb, &remote_addr, DEST_PORT, tcp_client_connected);
	if (err) {
		xil_printf("Error on tcp_connect: %d\n", err);
		tcp_client_close(pcb);
		return -1;
	}

	is_connected = 0;

	xil_printf("Waiting for server to accept connection\n");

	return 0;
}

static void tcp_client_close(struct tcp_pcb *pcb)
{
	err_t err;

	xil_printf("Closing Client Connection\n");

	is_connected = 0;

	if (pcb != NULL) {
		tcp_sent(pcb, NULL);
		tcp_recv(pcb,NULL);
		tcp_err(pcb, NULL);
		err = tcp_close(pcb);
		if (err != ERR_OK) {
			/* Free memory with abort */
			tcp_abort(pcb);
		}
	}
}

static err_t tcp_client_connected(void *arg, struct tcp_pcb *tpcb, err_t err)
{
	if (err != ERR_OK) {
		tcp_client_close(tpcb);
		xil_printf("Connection error\n");
		return err;
	}

	xil_printf("Connection to server established\n");

	//Store state (for callbacks)
	c_pcb = tpcb;
	is_connected = 1;

	//Set callback values & functions
	tcp_arg(c_pcb, NULL);
	tcp_recv(c_pcb, tcp_client_recv);
	tcp_sent(c_pcb, tcp_client_sent);
	tcp_err(c_pcb, tcp_client_err);



	//ADD CODE HERE to do when connection established

	//Just send a single packet
	/*u8_t apiflags = TCP_WRITE_FLAG_COPY | TCP_WRITE_FLAG_MORE;
	char send_buf[TCP_SEND_BUFSIZE];
	u32_t i;

	for(i = 0; i < TCP_SEND_BUFSIZE-1; i = i + 1)
	{
		send_buf[i] = i+'a';
	}
	send_buf[TCP_SEND_BUFSIZE-1] = '\n';

	//Loop until enough room in buffer (should be right away)
	while (tcp_sndbuf(c_pcb) < TCP_SEND_BUFSIZE);

	//Enqueue some data to send
	err = tcp_write(c_pcb, send_buf, TCP_SEND_BUFSIZE, apiflags);
	if (err != ERR_OK) {
		xil_printf("TCP client: Error on tcp_write: %d\n", err);
		return err;
	}

	//send the data packet
	err = tcp_output(c_pcb);
	if (err != ERR_OK) {
		xil_printf("TCP client: Error on tcp_output: %d\n",err);
		return err;
	}

	xil_printf("Packet data sent\n"); */

	//END OF ADDED CODE



	return ERR_OK;
}

static err_t tcp_client_recv(void *arg, struct tcp_pcb *tpcb, struct pbuf *p, err_t err)
{

	//If no data, connection closed
	if (!p) {
		xil_printf("No data received\n");
		tcp_client_close(tpcb);
		return ERR_OK;
	}

	//ADD CODE HERE to do on packet reception

	//Print message
	xil_printf("Packet received, %d bytes\n", p->tot_len);

	//Print packet contents to terminal
	char* packet_data = (char*) malloc(p->tot_len);
	pbuf_copy_partial(p, packet_data, p->tot_len, 0); //Note - inefficient way to access packet data
	u32_t i;

	for(i = 0; i < p->tot_len; i = i + 1)
		putchar(packet_data[i]);

	//END OF ADDED CODE

	//AKB ADDED START
	//value_recv = (unsigned int) strtoul(packet_data, NULL, 10);

	// Copy packet contents into value_recv
	u32_t j;
	u32 recv_placeholder;
	recv_placeholder = 0x00000000;

	for(j = 0; j < 4; j = j + 1) {
		recv_placeholder = (recv_placeholder << 8);
		u32 curr_char = (u32) (0x000000FF & packet_data[j]);
		recv_placeholder = recv_placeholder | curr_char;
	}

	value_recv = recv_placeholder;

	xil_printf("Data received: %08x\n", value_recv);
	//AKB ADDED END

	//Indicate done processing
	tcp_recved(tpcb, p->tot_len);

	//Free the received pbuf
	pbuf_free(p);

	return 0;
}

static err_t tcp_client_sent(void *arg, struct tcp_pcb *tpcb, u16_t len)
{


	//ADD CODE HERE to do on packet acknowledged

	//Print message
	xil_printf("Packet sent successfully, %d bytes\n", len);

	//END OF ADDED CODE



	return 0;
}

static void tcp_client_err(void *arg, err_t err)
{
	LWIP_UNUSED_ARG(err);
	tcp_client_close(c_pcb);
	c_pcb = NULL;
	xil_printf("TCP connection aborted\n");
}

