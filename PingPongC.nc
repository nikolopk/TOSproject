#include "Timer.h"
#include "printf.h"
#include "PingPong.h"
#include <UserButton.h>

module PingPongC @safe()
{
  uses interface Timer<TMilli> as Timer0;
  /*uses interface Timer<TMilli> as Timer1;
  uses interface Timer<TMilli> as Timer2;*/
  uses interface Leds;
  uses interface Boot;
  uses interface Notify<button_state_t>;
  uses interface Get<button_state_t>;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
}
implementation
{
  uint8_t moteState;
  message_t pkt;
  bool busy = FALSE;
  
  void sendMsg()
  {
        //counter++;
        if (!busy) {
          PingPongMsg* pipopkt = (PingPongMsg*)(call Packet.getPayload(&pkt, sizeof(PingPongMsg)));
          if (pipopkt == NULL) {
           return;
          }
          pipopkt->nodeid = TOS_NODE_ID;
          pipopkt->moteState = 1;
          if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(PingPongMsg)) == SUCCESS) {
            busy = TRUE;
          }
    }
  }

  event void Boot.booted()
  {
    call Notify.enable();
    //call AMControl.start();
  }

  event void Notify.notify( button_state_t state ) {
    if ( state == BUTTON_PRESSED ) {
      call AMControl.start();
      call Leds.led1Toggle();
      printf("Button Pressed!!\n");
      printfflush();
    }
  }

event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      //call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
      sendMsg();
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }

  event void Timer0.fired()
  {
      call Leds.led0On();
      call Leds.led2On();
      sendMsg();
  }

  

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) {
      printf("Message Send OK\n");
      printfflush();
      busy = FALSE;
    }
  }
  
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    if (len == sizeof(PingPongMsg)) {
      PingPongMsg* pipopkt = (PingPongMsg*)payload;
      call Leds.led0On();
      call Leds.led2On();
      call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
    }
    printf("Message Received\n");
    printfflush();
    return msg;
  }

}
