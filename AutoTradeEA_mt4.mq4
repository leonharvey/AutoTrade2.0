//+------------------------------------------------------------------+
//|                                              AutoTradeEA_mt4.mq4 |
//|				   GNU AFFERO GENERAL PUBLIC LICENSE |
//|					 Version 3, 19 November 2007 |
//|                   Date of this seed file creation: 20 March 2017 |
//|                                        Owner: leonharvey(github) |                    
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, GNU AFFERO GENERAL PUBLIC LICENSE."
#property link      "###"
#property version   "1.000"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+               
                                   // Numeric values for Inputs
extern double StopLoss   =1;       // Stop Loss 1 for default 0 for no StopLoss (0.01to .99 value)
extern double TakeProfit =60;      // Тake Рrofit

extern int    Period_MA_1=11;      // Moving Avg 1 Period 
extern int    Period_MA_2=31;      // Moving Avg 2 Period
extern int    shift_MA_1=0;		  // Shift for Avg 1 Period 
extern int    shift_MA_2=0;        // Shift for Avg 2 Period 

extern int    Period_MA_3=11;      // Moving Avg 3 Period
extern int    Period_MA_4=31;      // Moving Avg 4 Period 
extern int    shift_MA_3=2;		  // Shift for Avg 3 Period 
extern int    shift_MA_4=2;        // Shift for Avg 4 Period 

//Chandelier Exit Default vale is 22
extern int    atr_period =22;	   // ATR Period 
extern int    high_period=22;	   // Highest value on the consecutive bars 
extern int    low_period =22;	   // Lowest value on the consecutive bars  
extern int    shift_high =1;	   // Shift value for highest on the consecutive bars  
extern int    shift_low  =1;	   // Shift value for lowest on the consecutive bars

extern double Lots       =0.1;   // Lots to trade
extern int rsi_period    =14;    // RSI Period

 
// Global Variables
//|-----------------------------------------------------------------------------------|//

int 
	val_index,
	Ticket;						//To store order ticket
datetime 
	LastTradeTime = 0;          //Used for giving time gaps between trades
bool         
	Opn_B=false,                     // Check status for opening Buy
	Opn_S=false;                     // Check status for opening Sell
	
//**Chandelier Exit Method** variables  
double 
	rsi_value=iRSI(NULL,0,rsi_period,PRICE_CLOSE,0),//RSI Value,
	atr_value=iATR(NULL,0,atr_period,0), //Storing Rverage True Range
	val_high,
	val_low,
	sell_Final_SL,  //Final value of Stoploss to be taken for Sell Order 
	buy_Final_SL,   //Final value of Stoploss to be taken for Buy Order 
	sell_Final_TP,	//Final value of TakeProfit to be taken for Sell Order 
	buy_Final_TP;	//Final value of TakeProfit to be taken for Buy Order 
double 
   StopLevel,				//To be used as Stoploss incase original calculated Stoploss failed to place order
	MA_1 ,
	MA_2 ,
	MA_3,
	MA_4,
	SL, 
	TP,
	Lts=Lots;   
//--------------------------------------------------------------------------------------------
void OnInit()
{
StopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD);
//Print(StopLevel);
}

//Execution of start() begins
int start()
  {
  
  if(LocalTime() - LastTradeTime < 300)
   {
    Comment("Less than 600 seconds have elapsed after the last trade!",
            " The expert won't trade!"); 
    return(-1);
   }
  
  //RefreshRates();
   
   MA_1=iMA(NULL,0,Period_MA_1,0,MODE_SMA,PRICE_CLOSE,shift_MA_1); // МА_1
   MA_2=iMA(NULL,0,Period_MA_2,0,MODE_SMA,PRICE_CLOSE,shift_MA_2); // МА_2
   MA_3=iMA(NULL,0,Period_MA_3,0,MODE_SMA,PRICE_CLOSE,shift_MA_3); // МА_1
   MA_4=iMA(NULL,0,Period_MA_4,0,MODE_SMA,PRICE_CLOSE,shift_MA_4); // МА_2 
   
 //Checking for Buying  
 
  if ( MA_1>MA_2 && MA_3<MA_4 )         // When MA cross each other compare values of both side of intersection point
     {      
         // CloseAllOrders();Opn_S=false;                                 
         Opn_B=true;     
         // RefreshRates();                        // Refresh rates
     
          //Chandelier Exit for Stoploss calculation for Buy
          val_index=iHighest(NULL,0,MODE_HIGH,high_period,shift_high);  //--- calculating the highest value on the 22 consecutive bars in the range with shift
          if(val_index!=-1) val_high=High[val_index];
          else PrintFormat("Error in call iHighest. Error code=%d",GetLastError());
          buy_Final_SL =val_high-(atr_value*3);buy_Final_TP=val_high+(atr_value*3);
   
          SL=NormalizeDouble(buy_Final_SL*StopLoss,Digits);//
          TP=NormalizeDouble(Bid +(Bid-SL)*TakeProfit,Digits);
         // SL==Bid - (StopLoss+StopLevel)*Point;     // Calculating SL with Stoplevel
         // TP=Bid + (TakeProfit+StopLevel)*Point;    // Calculating TP with Stoplevel
         
          Ticket= OrderSend(Symbol(),OP_BUY,Lts,Ask,2,SL,TP);                              // Criterion for opening Buy
          if(Ticket<0)                 //Order was success
          Opn_B=true;
          else if (GetLast_ErrorInfo(GetLastError(),1)==1)      // Processing errors
         { 
            Ticket= OrderSend(Symbol(),OP_BUY,Lts,Ask,2,New_StopLoss(SL),TP); 
            if(GetLast_ErrorInfo(GetLastError(),2)==0)
            Alert("Buy Success");
         }       
     
    
    // Sleep(6000000); //sleep for 10 min=600000
    
     }
     
     
 //Checking for Selling  
   
 if (MA_1<MA_2 &&  MA_3>MA_4 )         // When MA cross each other compare values of both side of intersection point
     { 
      //CloseAllOrders(); Opn_B=false;                                 // ..MA 1 and 2 is large
       
      
      // RefreshRates();                        // Refresh rates
     

      //Chandelier Exit for Stoploss calculation for Sell
      val_index=iLowest(NULL,0,MODE_LOW,low_period,shift_low); //--- calculating the lowest value on the 22 consequtive bars in the range with shift
      if(val_index!=-1) val_low=Low[val_index];
      else PrintFormat("Error in iLowest. Error code=%d",GetLastError());
      sell_Final_SL = val_low+(3*atr_value);sell_Final_TP=val_low+(3*atr_value);
      
      //Chandelier Exit for Stoploss calculation for Buy
      SL=NormalizeDouble( sell_Final_SL*StopLoss,Digits);
      TP=NormalizeDouble(Ask -(SL-Ask)*TakeProfit,Digits);
      // SL=Ask + (StopLoss+StopLevel)*Point;     // Calculating SL with Stoplevel
      // TP=Ask - (TakeProfit+StopLevel)*Point;   // Calculating TP with Stoplevel
           
      Ticket=OrderSend(Symbol(),OP_SELL,Lts,Bid,2,SL,TP);                      
          
          if(Ticket<0)                 //Order was success
          Opn_S=true; 
          else if (GetLast_ErrorInfo(GetLastError(),2)==1)      // Processing errors
          {
          Alert("inside Sell 2 ",SL);
          Ticket= OrderSend(Symbol(),OP_SELL,Lts,Bid,2,NormalizeDouble( Bid - New_StopLoss(SL) * Point, Digits ),TP); 
          }                            
                                   
                                    // Criterion for opening Sell
     // Cls_B=true;                               // Criterion for closing Buy
    // Sleep(6000000);//sleep for 10 min=600000
     }
 
 LastTradeTime = LocalTime(); 
 return 0;
   }
//Execution of start() ends
//---------------------------------------------------------------------------------------------------


void CloseAllOrders()    //Function for closing all orders
{
 if(Opn_B==true || Opn_S==true)
 {
   int Total = OrdersTotal();
   for(int i=Total-1;i>=0;i--)
   {
    OrderSelect(i, SELECT_BY_POS);
    int type   = OrderType();

    bool result = false;
    
    switch(type)
    {
      //Close opened long positions  
      case OP_BUY       : result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 5, Red );
                          break;
      
      //Close opened short positions
      case OP_SELL      : result = OrderClose( OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 5, Red );
                          break;

      //Close pending orders
      case OP_BUYLIMIT  :
      case OP_BUYSTOP   :
      case OP_SELLLIMIT :
      case OP_SELLSTOP  : result = OrderDelete( OrderTicket() );
    }
    
    if(result == false)
    {
      Alert("Order " , OrderTicket() , " failed to close. Error:" , GetLastError() );
      Sleep(3000);
    }  
  }
     }
return;
}
//-------------------------------------------------------------- 
//--------------------------------------------------------------
int GetLast_ErrorInfo(int Error,int option)                        // Function of processing errors
  {
  string error_string;
   switch(Error)
     {                                                     
                               
      case 130: 
      {if(option==1)
      Alert("invalid stops(130) Buy 1");
      else
      Alert("invalid stops(130) Sell 2",NormalizeDouble( Bid - New_StopLoss(SL) * Point, Digits ));
      }                                            
         return(1);
      default:
      {if(option==1)
      Alert("Buy 1 success");
      else
      Alert("Sell 2 success",NormalizeDouble( Bid - New_StopLoss(SL) * Point, Digits ));
      }
       //Alert("Error occurred: ",Error);  // Other variants   
         return(0);                             // Exit the function
     }
  }
//--------------------------------------------------------------
double New_StopLoss(double Parametr)                      // Checking stop levels
  {
   double Min_Dist=MarketInfo(Symbol(),MODE_STOPLEVEL)+MarketInfo(Symbol(),MODE_BID);// Minimal distance
   if (Parametr > Min_Dist)                     // If less than allowed
     {
      Parametr=Min_Dist;                        // Sett allowed
     // Alert("Increased distance of stop level.");
     }
   return(Parametr);                            // Returning value
  }
//--------------------------------------------------------------
