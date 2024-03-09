//+------------------------------------------------------------------+
//|                                               mariaktitarova.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2023, tradesurf"
#property link      "https://tradesurf.io/"
#property version   "2.00"
#property strict
#property description "Contact us for more details."

#import "wininet.dll"
#define INTERNET_FLAG_PRAGMA_NOCACHE    0x00000100
#define INTERNET_FLAG_NO_CACHE_WRITE    0x04000000
#define INTERNET_FLAG_RELOAD            0x80000000

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int InternetOpenW(string sAgent, int lAccessType, string sProxyName, string sProxyBypass, int lFlags);
int InternetOpenUrlW(int   hInternetSession,string    sUrl,string    sHeaders="",int   lHeadersLength=0,int    lFlags=0,int   lContext=0);
int InternetReadFile(int hFile, uchar &sBuffer[],int lNumBytesToRead,int &lNumberOfBytesRead[]);
int InternetCloseHandle(int   hInet);
#import


int hSession_IEType;
int hSession_Direct;
int Internet_Open_Type_Preconfig = 0;
int Internet_Open_Type_Direct = 1;
int Internet_Open_Type_Proxy = 3;
int Buffer_LEN = 80;

#include <stderror.mqh>
#include <stdlib.mqh>




bool checked;
datetime NewDate;
int MetaID;


string AuthUrl;
string RiskUrl;
string TradeUrl;
input             string EA ="=============TRADE MANAGEMENT SETTINGS=============";//============================
input             string Key = "hZBW2amqqzSazsfuERrgr1it9QkdcmitewEIVOYJOa";//Input Key
input             double TradeAmount=1000;
input             string SymbolSuffix="";
input             int AtrPeriod=14;
input             string  StartTime="00:00"; //Start Time
input             string  StopTime="23:59"; //End Time
input             double TpReduce=20; // TpReduce %
input             double MaxGap=200;//Max Gap in Pips


bool Buy=false;
bool Sell=false;
int roundx = 2;
double point;
double TpReducex;
int digit=Digits;
int MagicNo=859;
double MaxAccountBala=0;
double InitailAccountBalance=0;
double dropdown=0;
string Text1,Text2;

//+------------------------------------------------------------------+
bool TradeTime()
  {
   bool result=false;

   datetime svt =StringToTime(TimeToString(TimeCurrent(), TIME_DATE) + " " + StartTime);
   datetime bvt =StringToTime(TimeToString(TimeCurrent(), TIME_DATE) + " " + StopTime);

   if(svt<bvt)
     {
      if(TimeCurrent()>=svt && TimeCurrent()<bvt)
         result=true;
     }
   else
     {
      if(TimeCurrent()>=svt || TimeCurrent()<bvt)
         result=true;
     }

   return(result);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() //
  {
   Text2="start";
// Broker digits
//---
   if(!VerifyTradingPermissions())
      return(INIT_FAILED);
   
   MetaID = AccountNumber();
   AuthUrl="http://149.28.238.50:8080/query-data?key="+Key+"&metaID="+(string)MetaID;
   
   InitailAccountBalance=AccountBalance();
   MaxAccountBala=InitailAccountBalance;
   
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool VerifyTradingPermissions()
  {
   if(!IsExpertEnabled())
     {
      Alert("Please enable AutoTrading on the MT4 terminal by pressing Ctrl+E");
      return (false);
     }


   if(!IsTradeAllowed())
     {
      Alert("Expert advisor is disabled! Please \"Allow live trading\" in the Expert Setting");
      return (false);
     }



//if(TerminalInfoInteger(TERMINAL_DLLS_ALLOWED)==0)
   if(!IsDllsAllowed())
     {
      //Print("here");
      // Print("dll: ",TerminalInfoInteger(TERMINAL_DLLS_ALLOWED));
      Alert("DLL Not Allowed! Enable DLL Import in the EA setting");
      ExpertRemove();
      return(false);
     }

   return (true);

  }



string PairsMap[];
string PairsMaped[];
string Pairs[];
double Overall_amount[];
double Base_Amount[];
double ATR_multiplier1[];
double ATR_multiplier2[];
double Candle_Body[];
string PairsTwo[];
double RR[];
double Order_multiplier1[];
double Order_multiplier2[];
double Order_multiplier3[];
double Order_multiplier4[];
double Fee[];
int TimeFrame[];
double TakeProfit;
double StopLoss;



bool Hedge1=false;
bool Hedge2=false;
bool Hedge3=false;



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ArraySum(double &array[])
  {
   double sum = 0;

// Get the size of the array
   int size = ArraySize(array);

// Iterate through the array and calculate the sum
   for(int i = 0; i < size; i++)
     {
      sum += array[i];
     }

   return sum;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RiskManager()
  {

   string RiskedUrl="";


   string url3 = "http://149.28.238.50:8080/view-json-4";

   RiskedUrl=url3;

   string res= GrabWeb(RiskedUrl);


   StringReplace(res,"{","");
   StringReplace(res,"}","");
   StringReplace(res,"\"","");
   StringReplace(res,"[","");

   res=StringTrimLeft(res);
   res=StringTrimRight(res);


   string sep="]";
   ushort u_sep;

   u_sep=StringGetCharacter(sep,0);
   int k=StringSplit(res,u_sep,PairsMap);

   ArrayResize(Pairs,ArraySize(PairsMap));
   ArrayResize(Overall_amount,ArraySize(PairsMap));

   ArrayResize(Base_Amount,ArraySize(PairsMap));
   ArrayResize(ATR_multiplier1,ArraySize(PairsMap));
   ArrayResize(ATR_multiplier2,ArraySize(PairsMap));
   ArrayResize(Candle_Body,ArraySize(PairsMap));
   ArrayResize(RR,ArraySize(PairsMap));
   ArrayResize(Order_multiplier1,ArraySize(PairsMap)); // pritom
   ArrayResize(Order_multiplier2,ArraySize(PairsMap)); // pritom
   ArrayResize(Order_multiplier3,ArraySize(PairsMap)); // pritom
   ArrayResize(Order_multiplier4,ArraySize(PairsMap)); // pritom
   ArrayResize(Fee,ArraySize(PairsMap)); // pritom
   ArrayResize(TimeFrame,ArraySize(PairsMap)); // pritom
   Text1="========================="+"\n";
   for(int i=0; i<ArraySize(PairsMap)-1; i++) //[1.5,2]
     {

      StringReplace(PairsMap[i],"[","");
      string sepd=":";
      ushort u_sepd;

      u_sepd=StringGetCharacter(sepd,0);
      int u=StringSplit(PairsMap[i],u_sepd,PairsMaped);

      if(ArraySize(PairsMaped)==2)//[1.5,2]
        {

         string seg=",";
         ushort u_seg;

         u_seg=StringGetCharacter(seg,0);
         int g=StringSplit(PairsMaped[1],u_seg,PairsTwo);

         ArrayResize(PairsTwo,12);

         Pairs[i] = PairsMaped[0]+SymbolSuffix;
         Overall_amount[i] =TradeAmount*(StrToDouble(PairsTwo[0])/100);
         Base_Amount[i] = (double)PairsTwo[1];
         ATR_multiplier1[i] =(double)PairsTwo[2] ;
         ATR_multiplier2[i] =(double)PairsTwo[3] ;
         Candle_Body[i] =(double)PairsTwo[4] ;
         RR[i] = (double)PairsTwo[4];
         Order_multiplier1[i] =(double)PairsTwo[5];
         Order_multiplier2[i] = (double)PairsTwo[6];
         Order_multiplier3[i] = (double)PairsTwo[7];
         Order_multiplier4[i] = (double)PairsTwo[8];
         
         Fee[i] = (double)PairsTwo[9];
         TimeFrame[i] =(int)PairsTwo[10];
         ////////////////////////////////////////////////
         StringReplace(Pairs[i],",","");
         Text1=Text1+Pairs[i]+":["+PairsTwo[0]+","+Base_Amount[i]+","+ATR_multiplier1[i]+","+ATR_multiplier2[i]+","+RR[i]+","+Order_multiplier1[i]+","+Order_multiplier2[0]
         +","+Order_multiplier3[i]+","+Order_multiplier4[i]+","+Fee[i]+","+TimeFrame[i]+"]"+"\n";
         Text1=Text1+"========================="+"\n";
        }

     }
//
   if(Text1!=Text2)
     {
      if(Text2!="start")
      {
       printf(Text1);
       Alert("Json Parameter Updated at "+TimeToString(TimeCurrent(),TIME_DATE|TIME_MINUTES));
      }
      /*printf(Text1);
      printf("Max Gap "+(string)MaxGap);
      printf("TPReducer "+(string)TpReduce);
      printf("Start Time("+StartTime+") Stop Time ("+StopTime+")");
      printf("Trade Amount="+(string)TradeAmount);
      Text2=Text1;*/
     }
   Comment(Text1);
   Operation();

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Operation()
  {
   for(int i=0; i<ArraySize(Pairs)-1; i++)
     {
      double open=iHigh(Pairs[i],TimeFrame[i],0);
      open=iOpen(Pairs[i],TimeFrame[i],1);
      double close=iClose(Pairs[i],TimeFrame[i],0);
      close=iClose(Pairs[i],TimeFrame[i],1);
      
      if(_LastError==ERR_NO_HISTORY_DATA||_LastError==ERR_HISTORY_WILL_UPDATED){
      while(!download_history(Pairs[i],TimeFrame[i]))
        {
         Sleep(1000); RefreshRates();
        }
      }
      
      digit=(int)MarketInfo(Pairs[i],MODE_DIGITS);
      point=MarketInfo(Pairs[i],MODE_POINT);
      if(digit==3||digit==5||digit==1)
        {
         point*=10;
        }
      double atrValue1x=ATR_multiplier1[i]*point;
      double atrValue2x= ATR_multiplier2[i]*point;
      double bodySizex=MathAbs(NormalizeDouble((iClose(Pairs[i],TimeFrame[i],1)-iOpen(Pairs[i],TimeFrame[i],1)),digit));
      
      datetime timecurrent=TimeCurrent();
      string now=TimeToString(timecurrent,TIME_MINUTES);
      string CandleTime=TimeToString(iTime(Pairs[i],TimeFrame[i],0),TIME_MINUTES);
      
      if(AllowTrade(Pairs[i],TimeFrame[i])&&now==CandleTime)
        {
         if(iClose(Pairs[i],TimeFrame[i],1)>iOpen(Pairs[i],TimeFrame[i],1))
           {
            if(bodySizex>=atrValue1x&&bodySizex<=atrValue2x)
              {
               double ask=NormalizeDouble(MarketInfo(Pairs[i],MODE_ASK),digit);
               TakeProfit=NormalizeDouble(ask+(bodySizex*((100-TpReduce)/100)),digit);
               StopLoss=NormalizeDouble(ask-(bodySizex*(1/RR[i])),digit) ;
               double slrange=NormalizeDouble(ask-StopLoss,digit);
               double Risk=GetRisk(Overall_amount[i],RR[i],Base_Amount[i],Order_multiplier1[i],Order_multiplier2[i],Order_multiplier3[i],Order_multiplier4[i],Fee[i],0);
               double lot=CalcLotSize(Overall_amount[i],Pairs[i],true,Risk,slrange);
               
               ResetLastError();
               double TPDist=NormalizeDouble(TakeProfit-ask,digit);
               double SLDist=NormalizeDouble(ask-StopLoss,digit);
               if(MathAbs(ask-iClose(Pairs[i],TimeFrame[i],1))>MaxGap*point) return;
               int t=OrderSend(Pairs[i],OP_BUY,lot,ask,100,StopLoss,TakeProfit,NULL,MagicNo,0,clrGreen);
               
               if(t>=0)
                 {
                  Print
                     (
                        "Cycle:",0,"---",
                        "Pair:",Pairs[i],"---",
                        "Amount:",Overall_amount[i],"---",
                        "getBuy :",Risk,"---",
                        "Sl dist:",slrange,"---",
                        "Lot:",lot,"---",
                        "TF:",TimeFrame[i],"---",
                        "MaxAccountBa:",MaxAccountBala,"---",
                        "DropDown:",dropdown,"---",
                        "PF:",RR[i],"---",
                        "TPRation:",TpReduce
                     );
                  ObjectDelete("upper"+Pairs[i]);
                  ObjectDelete("lower"+Pairs[i]);
                  GlobalVariableDel((string)MagicNo+"_"+"UpperZone_"+Pairs[i]);
                  GlobalVariableDel((string)MagicNo+"_"+"LowerZone_"+Pairs[i]);
                  
                  GlobalVariableSet((string)MagicNo+"_"+"Cycle_"+Pairs[i],0);
                  GlobalVariableSet((string)MagicNo+"_"+"TPDist_"+Pairs[i],TPDist);
                  GlobalVariableSet((string)MagicNo+"_"+"SLDIst_"+Pairs[i],SLDist);
                  GlobalVariableSet((string)MagicNo+"_"+"OrderT_"+Pairs[i],(int)timecurrent);
                  ObjectCreate(0,"upper"+Pairs[i],OBJ_HLINE,0,Time[0],iClose(Pairs[i],TimeFrame[i],1));
                  GlobalVariableSet((string)MagicNo+"_"+"UpperZone_"+Pairs[i],ask);
                  
                  double EntryPrice=NormalizeDouble(iClose(Pairs[i],TimeFrame[i],1)-(MathAbs(iOpen(Pairs[i],TimeFrame[i],1)-iClose(Pairs[i],TimeFrame[i],1))/2),Digits);
                  GlobalVariableSet((string)MagicNo+"_"+"LowerZone_"+Pairs[i],EntryPrice);
                  ObjectCreate(0,"lower"+Pairs[i],OBJ_HLINE,0,Time[0],EntryPrice);
                  
                  double halddist=MathAbs(iOpen(Pairs[i],TimeFrame[i],1)-iClose(Pairs[i],TimeFrame[i],1))/2;
                  TPDist=TPDist+halddist;
                  SLDist=SLDist-halddist;
                  GlobalVariableSet((string)MagicNo+"_"+"TPDist_2"+Pairs[i],TPDist);
                  GlobalVariableSet((string)MagicNo+"_"+"SLDIst_2"+Pairs[i],SLDist);
                  
                  TakeProfit=NormalizeDouble(EntryPrice-(TPDist),digit);
                  StopLoss=NormalizeDouble(EntryPrice+(SLDist),digit);
                  double Risk2=GetRisk(Overall_amount[i],RR[i],Base_Amount[i],Order_multiplier1[i],Order_multiplier2[i],Order_multiplier3[i],Order_multiplier4[i],Fee[i],1);
                  slrange=NormalizeDouble(StopLoss-EntryPrice,digit);
                  double lot2=CalcLotSize(Overall_amount[i],Pairs[i],true,Risk2,slrange);
                  
                  ResetLastError();
                  int y=OrderSend(Pairs[i],OP_SELLSTOP,lot2,EntryPrice,100,StopLoss,TakeProfit,NULL,MagicNo,0,clrRed);
                  if(y>=0)
                    {
                     Print
                     (
                        "Cycle:",1,"---",
                        "Pair:",Pairs[i],"---",
                        "Amount:",Overall_amount[i],"---",
                        "getBuy :",Risk2,"---",
                        "Sl dist:",slrange,"---",
                        "MaxAccountBa:",MaxAccountBala,"---",
                        "DropDown:",dropdown,"---",
                        "Lot:",lot2
                     );
                     
                     GlobalVariableSet((string)MagicNo+"_"+"Cycle_"+Pairs[i],1);
                    } 
                    else
                      {
                       Print(
                             "Pair:",Pairs[i],"---",
                             "Error while Opening Trade error:",(string)GetLastError(),"---",
                             "Entry Level:",(string)EntryPrice,"---",
                             "StopLoss:",(string)StopLoss,"---",
                             "TakeProfit:",(string) TakeProfit
                            );
                      }
                 }
                 else
                   {
                    Print(
                          "Pair:",Pairs[i],"---",
                          "Error while Opening Trade error:",(string)GetLastError(),"---",
                          "Entry Level:",(string)ask,"---",
                          "StopLoss:",(string)StopLoss,"---",
                          "TakeProfit:",(string) TakeProfit
                         );
                   }
                  

              }
           }
           else if(iClose(Pairs[i],TimeFrame[i],1)<iOpen(Pairs[i],TimeFrame[i],1))
                  {
                   if(bodySizex>=atrValue1x&&bodySizex<=atrValue2x)
                     {
                      double bid=NormalizeDouble(MarketInfo(Pairs[i],MODE_BID),digit);
                      TakeProfit=NormalizeDouble(bid-(bodySizex*((100-TpReduce)/100)),digit);
                      StopLoss=NormalizeDouble(bid+(bodySizex*(1/RR[i])),digit);
                      double slrange=NormalizeDouble(StopLoss-bid,digit);
                      double Risk=GetRisk(Overall_amount[i],RR[i],Base_Amount[i],Order_multiplier1[i],Order_multiplier2[i],Order_multiplier3[i],Order_multiplier4[i],Fee[i],0);
                      
                      double lot=CalcLotSize(Overall_amount[i],Pairs[i],true,Risk,slrange);
                      double TPDist=NormalizeDouble(bid-TakeProfit,digit);
                      double SLDist=NormalizeDouble(StopLoss-bid,digit);
                      
                      if(MathAbs(bid-iClose(Pairs[i],TimeFrame[i],1))>MaxGap*point) return;
                      ResetLastError();
                      int t=OrderSend(Pairs[i],OP_SELL,lot,bid,100,StopLoss,TakeProfit,NULL,MagicNo,0,clrRed);
                      if(t>=0)
                        {
                         Print
                           (
                              "Cycle:",0,"---",
                              "Pair:",Pairs[i],"---",
                              "Amount:",Overall_amount[i],"---",
                              "getBuy :",Risk,"---",
                              "Sl dist:",slrange,"---",
                              "Lot:",lot,"---",
                              "TF:",TimeFrame[i],"---",
                              "MaxAccountBa:",MaxAccountBala,"---",
                              "DropDown:",dropdown,"---",
                              "PF:",RR[i],"---",
                              "TPRation:",TpReduce
                           );
                           
                         ObjectDelete("upper"+Pairs[i]);
                         ObjectDelete("lower"+Pairs[i]);
                         GlobalVariableDel((string)MagicNo+"_"+"UpperZone_"+Pairs[i]);
                         GlobalVariableDel((string)MagicNo+"_"+"LowerZone_"+Pairs[i]);
                         
                         GlobalVariableSet((string)MagicNo+"_"+"Cycle_"+Pairs[i],0);
                         GlobalVariableSet((string)MagicNo+"_"+"TPDist_"+Pairs[i],TPDist);
                         GlobalVariableSet((string)MagicNo+"_"+"SLDIst_"+Pairs[i],SLDist);
                         GlobalVariableSet((string)MagicNo+"_"+"OrderT_"+Pairs[i],(int)timecurrent);
                         
                         ObjectCreate(0,"lower"+Pairs[i],OBJ_HLINE,0,Time[0],iClose(Pairs[i],TimeFrame[i],1));
                         GlobalVariableSet((string)MagicNo+"_"+"LowerZone_"+Pairs[i],bid);
                         
                         double EntryPrice=NormalizeDouble(iClose(Pairs[i],TimeFrame[i],1)+(MathAbs(iOpen(Pairs[i],TimeFrame[i],1)-iClose(Pairs[i],TimeFrame[i],1))/2),Digits);
                         GlobalVariableSet((string)MagicNo+"_"+"UpperZone_"+Pairs[i],EntryPrice);
                         ObjectCreate(0,"upper"+Pairs[i],OBJ_HLINE,0,Time[0],EntryPrice);
                         double halddist=MathAbs(iOpen(Pairs[i],TimeFrame[i],1)-iClose(Pairs[i],TimeFrame[i],1))/2;
                         TPDist=TPDist+halddist;
                         SLDist=SLDist-halddist;
                         GlobalVariableSet((string)MagicNo+"_"+"TPDist_2"+Pairs[i],TPDist);
                         GlobalVariableSet((string)MagicNo+"_"+"SLDIst_2"+Pairs[i],SLDist);
                         
                         TakeProfit=NormalizeDouble(EntryPrice+TPDist,digit);
                         StopLoss=NormalizeDouble(EntryPrice-SLDist,digit);
                         double Risk2=GetRisk(Overall_amount[i],RR[i],Base_Amount[i],Order_multiplier1[i],Order_multiplier2[i],Order_multiplier3[i],Order_multiplier4[i],Fee[i],1);
                         slrange=NormalizeDouble(EntryPrice-StopLoss,digit);
                         double lot2=CalcLotSize(Overall_amount[i],Pairs[i],true,Risk2,slrange);
                        
                         
                         int y=OrderSend(Pairs[i],OP_BUYSTOP,lot2,EntryPrice,100,StopLoss,TakeProfit,NULL,MagicNo,0,clrGreen);
                         if(y>=0)
                           {
                            Print
                              (
                                 "Cycle:",1,"---",
                                 "Pair:",Pairs[i],"---",
                                 "Amount:",Overall_amount[i],"---",
                                 "getBuy :",Risk2,"---",
                                 "Sl dist:",slrange,"---",
                                 "MaxAccountBa:",MaxAccountBala,"---",
                                 "DropDown:",dropdown,"---",
                                 "Lot:",lot2
                              );
                            GlobalVariableSet((string)MagicNo+"_"+"Cycle_"+Pairs[i],1);
                           }
                         else
                           {
                            Print(
                             "Pair:",Pairs[i],"---",
                             "Error while Opening Trade error:",(string)GetLastError(),"---",
                             "Entry Level:",(string)EntryPrice,"---",
                             "StopLoss:",(string)StopLoss,"---",
                             "TakeProfit:",(string) TakeProfit
                            );
                           }
                        }
                        else
                          {
                           Print(
                             "Pair:",Pairs[i],"---",
                             "Error while Opening Trade error:",(string)GetLastError(),"---",
                             "Entry Level:",(string)bid,"---",
                             "StopLoss:",(string)StopLoss,"---",
                             "TakeProfit:",(string) TakeProfit
                            );
                          }
                      
                      

                     }
                  }
        }
     }
  }
  
bool AllowTrade(string symb, int tf)
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS))
        {
         if(OrderSymbol()==symb&&OrderMagicNumber()==MagicNo)
           {
            return false;
           }
        }
     }
   for(int i=OrdersHistoryTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
        {
         if(OrderSymbol()==symb&&OrderMagicNumber()==MagicNo)
           {
            if(OrderCloseTime()>=iTime(symb,tf,1))
              {
               return false;
              }
            else break;

           }
        }
     }
   
   return true;
  }
bool download_history(string symb,int tf)
{
 ResetLastError();
 double open=iHigh(symb,tf,0);
 open=iOpen(symb,tf,1);
 double close=iClose(symb,tf,0);
 close=iClose(symb,tf,1);
 datetime time=iTime(symb,tf,0);   
 if(_LastError==ERR_HISTORY_WILL_UPDATED||_LastError==ERR_NO_HISTORY_DATA) return false;
 if(iTime(NULL,tf,0)!=time) return false;
 return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int hSession(bool Direct)
  {
   string InternetAgent;
   if(hSession_IEType == 0)
     {
      InternetAgent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; Q312461)";
      hSession_IEType = InternetOpenW(InternetAgent, Internet_Open_Type_Preconfig, "0", "0", 0);
      hSession_Direct = InternetOpenW(InternetAgent, Internet_Open_Type_Direct, "0", "0", 0);
     }
   if(Direct)
     {
      return(hSession_Direct);
     }
   else
     {
      return(hSession_IEType);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GrabWeb(string strUrl)
  {
   int   hInternet;
   int      iResult;
   int   lReturn[]   = {1};
   uchar sBuffer[1024];
   int   bytes;

   string strWebPage="";
   uint flags=INTERNET_FLAG_NO_CACHE_WRITE | INTERNET_FLAG_PRAGMA_NOCACHE | INTERNET_FLAG_RELOAD;

   hInternet = InternetOpenUrlW(hSession(FALSE), strUrl, NULL, 0, flags);

   if(hInternet == 0)
      return("");
   iResult = InternetReadFile(hInternet, sBuffer, Buffer_LEN, lReturn);

   if(iResult == 0)
      return("");

   bytes = lReturn[0];
   strWebPage = CharArrayToString(sBuffer, 0, lReturn[0]);

   while(lReturn[0] != 0)
     {
      iResult = InternetReadFile(hInternet, sBuffer, Buffer_LEN, lReturn);
      if(lReturn[0]==0)
         break;
      bytes = bytes + lReturn[0];
      strWebPage = strWebPage + CharArrayToString(sBuffer, 0, lReturn[0]);
     }
   iResult = InternetCloseHandle(hInternet);
   if(iResult == 0)
      return("");


   return(strWebPage);
  }


//?????????????????????????????????????????????????????????????????????????????????????????????????????
//? DEINITIALIZATION----------------------------------------------------------------------------------?
//?????????????????????????????????????????????????????????????????????????????????????????????????????
void OnDeinit(const int reason)
  {

   if(reason==REASON_PARAMETERS ||
      reason==REASON_RECOMPILE ||
      reason==REASON_ACCOUNT)
     {
      checked=false;
     }

   EventKillTimer();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetPoint(string sym)
  {
   double poit=SymbolInfoDouble(sym,SYMBOL_POINT);

   double mp = 1;
   if(poit==0.00001 || poit==0.001)
     {
      mp = 10;
     }

   if(StringFind(Symbol(),"XAU")==0)
     {
      mp = 1;
     }

   if(StringFind(Symbol(),"XAG")==0)
     {
      mp = 0.1;
     }

   if(SymbolInfoDouble(NULL,SYMBOL_BID)>1000)
     {
      mp = 1;
     }

   return(mp);
  }

// added by pritom

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   string now=TimeToString(TimeCurrent(),TIME_MINUTES);
   if(AccountBalance()>MaxAccountBala) MaxAccountBala=AccountBalance();
   for(int i=0; i<ArraySize(Pairs)-1; i++)
     {
      double open=iHigh(Pairs[i],TimeFrame[i],0);
      open=iOpen(Pairs[i],TimeFrame[i],1);
      double close=iClose(Pairs[i],TimeFrame[i],0);
      close=iClose(Pairs[i],TimeFrame[i],1);
      
      if(_LastError==ERR_NO_HISTORY_DATA||_LastError==ERR_HISTORY_WILL_UPDATED){
      while(!download_history(Pairs[i],TimeFrame[i]))
        {
         Sleep(1000); RefreshRates();
        }
      }
      int checkopen=CheckOpenTrade(Pairs[i]);
      int cycle=(int)GlobalVariableGet((string)MagicNo+"_"+"Cycle_"+Pairs[i]);
      digit=(int)MarketInfo(Pairs[i],MODE_DIGITS);
      
      double Risk=GetRisk(Overall_amount[i],RR[i],Base_Amount[i],Order_multiplier1[i],Order_multiplier2[i],Order_multiplier3[i],Order_multiplier4[i],Fee[i],0);
      if(cycle+1==1)Risk=GetRisk(Overall_amount[i],RR[i],Base_Amount[i],Order_multiplier1[i],Order_multiplier2[i],Order_multiplier3[i],Order_multiplier4[i],Fee[i],1);
      if(cycle+1==2)Risk=GetRisk(Overall_amount[i],RR[i],Base_Amount[i],Order_multiplier1[i],Order_multiplier2[i],Order_multiplier3[i],Order_multiplier4[i],Fee[i],2);
      if(cycle+1==3)Risk=GetRisk(Overall_amount[i],RR[i],Base_Amount[i],Order_multiplier1[i],Order_multiplier2[i],Order_multiplier3[i],Order_multiplier4[i],Fee[i],3);
       
      if(checkopen==1&&cycle<3)
        {
         double EntryLevel=NormalizeDouble(GlobalVariableGet((string)MagicNo+"_"+"UpperZone_"+Pairs[i]),digit);
         TakeProfit=NormalizeDouble(EntryLevel+GlobalVariableGet((string)MagicNo+"_"+"TPDist_"+Pairs[i]),digit);
         StopLoss=NormalizeDouble(EntryLevel-GlobalVariableGet((string)MagicNo+"_"+"SLDIst_"+Pairs[i]),digit);
         if(cycle+1==1||cycle+1==3)
           {
            TakeProfit=NormalizeDouble(EntryLevel+GlobalVariableGet((string)MagicNo+"_"+"TPDist_2"+Pairs[i]),digit);
            StopLoss=NormalizeDouble(EntryLevel-GlobalVariableGet((string)MagicNo+"_"+"SLDIst_2"+Pairs[i]),digit);
           }
         double slrange=NormalizeDouble(EntryLevel-StopLoss,digit);
         
         double lots=CalcLotSize(Overall_amount[i],Pairs[i],true,Risk,slrange);
         
         //if(MarketInfo(Pairs[i],MODE_ASK)<EntryLevel)
           {
            int t=OrderSend(Pairs[i],OP_BUYSTOP,lots,EntryLevel,100,StopLoss,TakeProfit,NULL,MagicNo,0,clrGreen);
            if(t>=0)
              {
               cycle++;
               Print
                  (
                     "Cycle:",cycle,"---",
                     "Pair:",Pairs[i],"---",
                     "Amount:",Overall_amount[i],"---",
                     "getBuy :",Risk,"---",
                     "Sl dist:",slrange,"---",
                     "MaxAccountBa:",MaxAccountBala,"---",
                     "DropDown:",dropdown,"---",
                     "Lots:",lots
                  ); 
               GlobalVariableSet((string)MagicNo+"_"+"Cycle_"+Pairs[i],cycle);
              }
              else
                {
                 Print(
                       "Pair:",Pairs[i],"---",
                       "Error while Opening Trade error:",(string)GetLastError(),"---",
                       "Entry Level:",(string)EntryLevel,"---",
                       "StopLoss:",(string)StopLoss,"---",
                       "TakeProfit:",(string) TakeProfit
                      );
                }
           }
        }
        else if(checkopen==-1&&cycle<3)
               {
                double EntryLevel=NormalizeDouble(GlobalVariableGet((string)MagicNo+"_"+"LowerZone_"+Pairs[i]),digit);
                TakeProfit=NormalizeDouble(EntryLevel-GlobalVariableGet((string)MagicNo+"_"+"TPDist_"+Pairs[i]),digit);
                StopLoss=NormalizeDouble(EntryLevel+GlobalVariableGet((string)MagicNo+"_"+"SLDIst_"+Pairs[i]),digit);
                if(cycle+1==1||cycle+1==3)
                  {
                   TakeProfit=NormalizeDouble(EntryLevel-GlobalVariableGet((string)MagicNo+"_"+"TPDist_2"+Pairs[i]),digit);
                   StopLoss=NormalizeDouble(EntryLevel+GlobalVariableGet((string)MagicNo+"_"+"SLDIst_2"+Pairs[i]),digit);
                  }
                
                double slrange=NormalizeDouble(StopLoss-EntryLevel,digit);
                double lots=CalcLotSize(Overall_amount[i],Pairs[i],true,Risk,slrange);
                
                //if(MarketInfo(Pairs[i],MODE_BID)>EntryLevel)
                  {
                   int t=OrderSend(Pairs[i],OP_SELLSTOP,lots,EntryLevel,100,StopLoss,TakeProfit,NULL,MagicNo,0,clrRed);
                   if(t>=0)
                     {
                      cycle++;
                      Print
                        (
                           "Cycle:",cycle,"---",
                           "Pair:",Pairs[i],"---",
                           "Amount:",Overall_amount[i],"---",
                           "getBuy :",Risk,"---",
                           "MaxAccountBa:",MaxAccountBala,"---",
                           "DropDown:",dropdown,"---",
                           "Sl dist:",slrange,"---",
                           "Lots:",lots
                        );
                      GlobalVariableSet((string)MagicNo+"_"+"Cycle_"+Pairs[i],cycle);
                     }
                     else
                       {
                        Print(
                             "Pair:",Pairs[i],"---",
                             "Error while Opening Trade error:",(string)GetLastError(),"---",
                             "Entry Level:",(string)EntryLevel,"---",
                             "StopLoss:",(string)StopLoss,"---",
                             "TakeProfit:",(string) TakeProfit
                            );
                       }
                  }
               }
     }
   if(now>=StartTime&&now<StopTime)
     {
      RiskManager();
     }
  }

double GetRisk(double overalamount,double pf,double baseRisk,double ordermultiplier1,double ordermultiplier2,double ordermultiplier3,double ordermultiplier4,double fee,int cycle)
 {
  double InitialRisk=(overalamount*baseRisk)/100;
  // TpReduce
  pf = pf - (pf*TpReduce/100);
  double pfactor=pf*2;
  for(int i = 0; i <=3; i++)
    {
     dropdown=0;
     double diff=MaxAccountBala-AccountBalance();
     if(diff>0) dropdown=diff;
     
     if(cycle==0)
       {
        double val=(overalamount*baseRisk)/100;
        double orderval=val*ordermultiplier1+(dropdown*fee);
        return orderval;
       }
       else if(cycle==1)
              {
               double val1=(overalamount*baseRisk)/100;
               double orderval1=val1*ordermultiplier1;
               
               double val2=orderval1/pfactor;
               double orderval2=(val2*ordermultiplier2)+(dropdown*fee);
               return orderval2;
              }
              else if(cycle==2)
                     {
                      double val1=(overalamount*baseRisk)/100;
                      double orderval1=val1*ordermultiplier1;
                      
                      double val2=orderval1/pfactor;
                      double orderval2=val2*ordermultiplier2;
                      
                      double val3=(orderval2/pf)-(orderval1*pf);
                      double orderval3=(val3*ordermultiplier3)+(dropdown*fee);
                      return orderval3;
                     }
                     else if(cycle==3)
                            {
                             double val1=(overalamount*baseRisk)/100;
                             double orderval1=val1*ordermultiplier1;
                            
                             double val2=orderval1/pfactor;
                             double orderval2=val2*ordermultiplier2;
                            
                             double val3=(orderval2/pf)-(orderval1*pf);
                             double orderval3=(val3*ordermultiplier3);
                             
                             double val4=(orderval3/pfactor)+(orderval1/pfactor)-(orderval2*pfactor);
                             double ordervalue4=(val4*ordermultiplier4)+(dropdown*fee);
                             return ordervalue4;
                            }
    }
  return 0;
 }

int CheckOpenTrade(string PairSymbo)
  {
   int Orders=0;
   bool OpenTrade=true;
   int Dire=0;
   bool PendOrder=false;
   int LastO=(int)GlobalVariableGet((string)MagicNo+"_"+"OrderT_"+PairSymbo);
   for(int i=OrdersHistoryTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
        {
         if(OrderSymbol()==PairSymbo&&OrderMagicNumber()==MagicNo)
           {
            if((int)OrderOpenTime()>=LastO&&OrderClosePrice()>OrderOpenPrice()&&OrderType()==OP_BUY)
              {
               CloseOrders(PairSymbo); return 0;
              }
              else if((int)OrderOpenTime()>=LastO&&OrderClosePrice()<OrderOpenPrice()&&OrderType()==OP_SELL)
                     {
                      CloseOrders(PairSymbo); return 0;
                     }

           }
        }
     }
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS))
        {
         if(OrderSymbol()==PairSymbo&&OrderMagicNumber()==MagicNo)
           {
            if(Dire==0&&OrderType()==OP_BUY) Dire=1;
            else if(Dire==0&&OrderType()==OP_SELL) Dire=-1;
            if(OrderType()==OP_BUYSTOP||OrderType()==OP_SELLSTOP)PendOrder=true; 
           }
        }
     }
   if(Dire==1&&!PendOrder)
     {
      return -1;
      
     }
     else if(Dire==-1&&!PendOrder)
            {
             return 1;
            }
   return 0;
  }

void CloseOrders(string PairSymbo)
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS))
        {
         if(OrderSymbol()==PairSymbo&&OrderMagicNumber()==MagicNo)
           {
            if(OrderType()==OP_BUY)
              {
               bool t=OrderClose(OrderTicket(),OrderLots(),MarketInfo(PairSymbo,MODE_BID),100,clrRed);
              } 
              else if(OrderType()==OP_SELL)
                     {
                      bool t=OrderClose(OrderTicket(),OrderLots(),MarketInfo(PairSymbo,MODE_ASK),100,clrRed);
                     }
                     else bool t=OrderDelete(OrderTicket(),clrNONE);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalcLotSize(const double argAccountEquity,
                   const string argSymbol,
                   const bool   argDynamicLotSize,
                   const double argEquityPercent,
                   const double argStopLoss)
  {
   double LotSize=MarketInfo(argSymbol,MODE_MINLOT);
   if(argDynamicLotSize && argStopLoss > 0)
     {
      double RiskAmount = argEquityPercent;
      double units=MarketInfo(argSymbol,MODE_TICKVALUE)/MarketInfo(argSymbol,MODE_TICKSIZE);
      int lotdavid=0;
      
      if(LotSize==0.1) lotdavid=1;
      else if(LotSize==0.01) lotdavid=2;
      
      double cbtickvalue=RiskAmount/(argStopLoss*units);
      LotSize=NormalizeDouble(cbtickvalue,lotdavid);
      
      double minLots = MarketInfo(argSymbol, MODE_MINLOT);
      double maxLots = MarketInfo(argSymbol, MODE_MAXLOT);
      if(LotSize<minLots) LotSize=minLots;
      if(LotSize>maxLots) LotSize=maxLots;
      return LotSize;
     }
//else
   return LotSize;
  }

