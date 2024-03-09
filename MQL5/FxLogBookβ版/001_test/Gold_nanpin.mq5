//+------------------------------------------------------------------+
//
//	 Expert Adviser Create by FxLogBook 
//	 EA作成機による自動生成 
//	 Gold_Nanpin
//	 For MQL5
//
//+------------------------------------------------------------------+

#property copyright "為替じじい"
#property link "https://www.fxlogbook.jp/"
#property link "https://ameblo.jp/fx-kamisama" // 開発者ブログ 


//+------------------------------------------------------------------+
//				パラメーター設定
//+------------------------------------------------------------------+

input string C0="---- Base Setting ----";
input int MAGIC = 0;
input int Slippage=3;
input int MaxSpread=45;


//取引ロット関連
input int MaxPosition=1;
input double BaseLots=0.01;
input int takeprofit=5;
input int stoploss=0;
input int exitTypePer=1;//BE発動pips

//マーチンゲール 
input int LotsAdjustPer=10;//最大マーチンゲール実施回数 
input double LotsAdjustPer2=1.75;//マーチン倍率 

//その他項目 
double Lots;
datetime Time;
int iBars=10;

input string C1="フィルター|ADX +DIと-DIの位置とADXが一定値以上";
ENUM_TIMEFRAMES TimeScale1 = PERIOD_CURRENT;
int Entry1 = 1;//1_直近確定の足、2_二本前、3_三本前  
input int ADX1_period = 14; //ADX期間
input double ADX1_value = 40; //しきい値



//インジケーター矢印の幅
input int AllowNarrow=10; 

//+------------------------------------------------------------------+
//				一般関数
//+------------------------------------------------------------------+

double AdjustPoint(string Currency)//ポイント調整
{
	 long Symbol_Digits=SymbolInfoInteger(Currency,SYMBOL_DIGITS);
	 double Calculated_Point=0;
	 if (Symbol_Digits==2 || Symbol_Digits==3)
	 {
		 Calculated_Point=0.01;
	 }
	 else if (Symbol_Digits==4 || Symbol_Digits==5)
	 {
		 Calculated_Point=0.0001;
	 }
	 else if (Symbol_Digits==1)
	 {
		 Calculated_Point=0.1;
	 }
	 else if (Symbol_Digits==0)
	 {
		 Calculated_Point=1;
	 }
	 return(Calculated_Point);
}

int AdjustSlippage(string Currency,int Slippage_pips )//スリッページ調整
{
	 int Calculated_Slippage=0;
	 long Symbol_Digits=SymbolInfoInteger(Currency,SYMBOL_DIGITS);
	 if (Symbol_Digits==2 || Symbol_Digits==3)
	 {
		 Calculated_Slippage=Slippage_pips;
	 }
	 else if (Symbol_Digits==4 || Symbol_Digits==5)
	 {
		 Calculated_Slippage=Slippage_pips*10;
	 }
	 return(Calculated_Slippage); 
}

int LongPosition()//ロングポジション数を取得
{
	 int buys=0;
	 int total=PositionsTotal();
	 ulong ticket=0;
	 ulong PositionMagic=0;
	 long type;
	 string symbol;
	 for(int i=total-1;i>=0;i--)
	 {
		 ticket=PositionGetTicket(i); 
		 symbol=PositionGetString(POSITION_SYMBOL); 
		 PositionMagic=PositionGetInteger(POSITION_MAGIC);
		 type  =PositionGetInteger(POSITION_TYPE); 
		 if(symbol==_Symbol && PositionMagic==MAGIC && type==POSITION_TYPE_BUY )
		 {
			 buys++;
		 }
	 }
	 return(buys);
}

int ShortPosition()//ショートポジション数を取得
{
	 int sells=0;
	 int total=PositionsTotal();
	 ulong ticket=0;
	 ulong PositionMagic=0;
	 long type;
	 string symbol;
	 for(int i=total-1;i>=0;i--)
	 {
		 ticket=PositionGetTicket(i); 
		 symbol=PositionGetString(POSITION_SYMBOL); 
		 PositionMagic=PositionGetInteger(POSITION_MAGIC);
		 type  =PositionGetInteger(POSITION_TYPE); 
		 if(symbol==_Symbol && PositionMagic==MAGIC && type==POSITION_TYPE_SELL )
		 {
			 sells++;
		 }
	 }
	 return(sells);
}

//+------------------------------------------------------------------+
//				エントリ関連関数
//+------------------------------------------------------------------+

//ポジションエントリ関数
void OpenOrder(int EntryPosition)
{
	 //ロットサイズ調整
	 Lots=LotsAdjustment(LotsAdjustPer,LotsAdjustPer2);//マーチンゲール
	 
	 double Bid, Ask;
	 MqlTick tick;
	 SymbolInfoTick(_Symbol, tick);
	 Bid = tick.bid;
	 Ask = tick.ask;
	 double SL=0;
	 double TP=0;
	 
	 //成り行き注文
	 MqlTradeRequest request={};
	 MqlTradeResult result={};
	 request.action=TRADE_ACTION_DEAL; 
	 request.symbol=_Symbol;  
	 request.volume=Lots;
	 
	 //買い注文
	 if (EntryPosition==1) 
	 {
		 request.type=ORDER_TYPE_BUY; 
		 request.price=SymbolInfoDouble(Symbol(),SYMBOL_ASK); // 発注価格 
		 if (stoploss!=0) SL=Ask-stoploss*AdjustPoint(_Symbol);
		 if (takeprofit!=0) TP=Ask+takeprofit*AdjustPoint(_Symbol);
	 }
	 //売り注文
	 if (EntryPosition==-1)  
	 {
		 request.type=ORDER_TYPE_SELL;  // 注文タイプ
		 request.price=SymbolInfoDouble(Symbol(),SYMBOL_BID); // 発注価格
		 if(stoploss!=0) SL=Bid+stoploss*AdjustPoint(_Symbol);
		 if(takeprofit!=0) TP=Bid-takeprofit*AdjustPoint(_Symbol);
	 }
	 request.tp = TP;
	 request.sl = SL;
	 request.comment="Gold_Nanpin";  
	 request.deviation = Slippage; 
	 request.magic=MAGIC;  
		 
	 bool ret=OrderSend(request,result);
}

//ポジション数調整関数 
double LotsAdjustment(int MaxMartin, double Multi)
{
	 int Loss_Count = 0;
	 
	 HistorySelect(0,TimeCurrent());
	 int total=HistoryDealsTotal(); 
	 ulong ticket=0; 
	 ulong HistoryMagic=0;
	 string symbol; 
	 double profit=0; 
	 ulong reason; 
	 for(int i=total-1;i>=0;i--) 
	 {
		 ticket=HistoryDealGetTicket(i);
		 bool res=HistoryDealSelect(ticket);
		 symbol=HistoryDealGetString(ticket,DEAL_SYMBOL); 
		 HistoryMagic=HistoryDealGetInteger(ticket,DEAL_MAGIC); 
		 profit=HistoryDealGetDouble(ticket,DEAL_PROFIT); 
		 reason=HistoryDealGetInteger(ticket,DEAL_ENTRY); 
		 if (HistoryMagic==MAGIC && symbol==_Symbol && (reason==DEAL_ENTRY_OUT || reason==DEAL_ENTRY_INOUT || reason==DEAL_ENTRY_OUT_BY )  )
		 {
			 if(profit<=0)
			 {
			   Loss_Count++;
			 }
			 else if(profit>0)
			 {
			   break;
			 }
		 }
	 }
	 if (Loss_Count>=MaxMartin)
	 {
		 Loss_Count=MaxMartin;
	 }
	 double LotSize= BaseLots*MathPow(Multi,Loss_Count);
	 if (LotSize>=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX))
	 {
		 LotSize=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
	 }
	 return(LotSize);
}

//+------------------------------------------------------------------+
//				エグジット関連関数
//+------------------------------------------------------------------+

//ポジションクローズ関数
void CloseOrder(int ClosePosition)
{
	 MqlTradeRequest request={};
	 MqlTradeResult  result={};
	 int total=PositionsTotal(); 
	 for(int i=total-1;i>=0;i--) 
	 {
		 //ポジション情報を取得 
		 ulong  position_ticket=PositionGetTicket(i); //ポジションチケット
		 string position_symbol=PositionGetString(POSITION_SYMBOL);  //シンボル 
		 ulong  magic=PositionGetInteger(POSITION_MAGIC); //ポジションのMagicNumber
		 double volume=PositionGetDouble(POSITION_VOLUME); // ポジションボリューム
		 ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);   // ポジションタイプ
		 double profit=PositionGetDouble(POSITION_PROFIT);
		 if(magic==MAGIC && position_symbol==_Symbol )
		 {
		 //注文のパラメータ設定
		 request.action   =TRADE_ACTION_DEAL;   
		 request.position =position_ticket;   
		 request.symbol   =position_symbol; 
		 request.volume   =volume;  
		 request.deviation=50;
		 request.magic    =MAGIC; 
		 if(type==POSITION_TYPE_BUY && (ClosePosition==1||ClosePosition==0) )
		 {
		 request.price=SymbolInfoDouble(position_symbol,SYMBOL_BID);
		 request.type =ORDER_TYPE_SELL;
		 request.comment="Gold_Nanpin";  
		 bool ret=OrderSend(request,result);
		 }
		 else if(type==POSITION_TYPE_SELL && (ClosePosition==-1 || ClosePosition==0 ))
		 {
		 request.price=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
		 request.type =ORDER_TYPE_BUY;
		 request.comment="Gold_Nanpin";  
		 bool ret=OrderSend(request,result);
		 }
		 }
	 }
}

//ブレークイーブンストップ関数
void BreakEvenStop()
{
	 double Bid, Ask;
	 MqlTick tick;
	 SymbolInfoTick(_Symbol, tick);
	 Bid = tick.bid;
	 Ask = tick.ask;
	 
	 double Pips_Profit;
	 double Min_Profit;
	 bool res;
	 
	 int total=PositionsTotal(); 
	 ulong ticket=0;
	 ulong PositionMagic=0;
	 long type; 
	 string symbol; 
	 double openPrice=0;
	 double currentPrice=0;
	 double StopLoss=0;
	 double TakeProfit=0;
	 
	 MqlTradeRequest request={};
	 MqlTradeResult  result={};
	 for(int i=total-1;i>=0;i--) 
	 {
		 ZeroMemory(request);
		 ZeroMemory(result);
	 
		 ticket=PositionGetTicket(i); 
		 PositionMagic=PositionGetInteger(POSITION_MAGIC); 
		 symbol=PositionGetString(POSITION_SYMBOL); 
		 type=PositionGetInteger(POSITION_TYPE); 
		 openPrice=PositionGetDouble(POSITION_PRICE_OPEN); 
		 currentPrice=PositionGetDouble(POSITION_PRICE_CURRENT);
		 StopLoss=PositionGetDouble(POSITION_SL);
		 TakeProfit=PositionGetDouble(POSITION_TP);
		 if(symbol==_Symbol && PositionMagic==MAGIC)
		 {
			 if(type==POSITION_TYPE_BUY)
			 {
				 Pips_Profit=Bid-openPrice;
				 Min_Profit=exitTypePer*AdjustPoint(_Symbol);
				 if (Pips_Profit>=Min_Profit && openPrice!=StopLoss)
				 {
				   request.action=TRADE_ACTION_SLTP; 
				   request.symbol=_Symbol;  
				   request.position=ticket; 
				   request.magic=MAGIC;  
				   request.sl=openPrice; 
				   request.tp=TakeProfit; 
				   request.comment="Gold_Nanpin";  
				   res=OrderSend(request,result); 
				 }
			 }
			 else if(type==POSITION_TYPE_SELL)
			 {
				 Pips_Profit=openPrice-Ask;
				 Min_Profit=exitTypePer*AdjustPoint(_Symbol);
				 if (Pips_Profit>=Min_Profit && openPrice!=StopLoss)
				 {
				   request.action=TRADE_ACTION_SLTP; 
				   request.symbol=_Symbol;  
				   request.position=ticket; 
				   request.magic=MAGIC;  
				   request.sl=openPrice; 
				   request.tp=TakeProfit; 
				   request.comment="Gold_Nanpin";  
				   res=OrderSend(request,result); 
				 }
			 }
		 }
	 }
}

//+------------------------------------------------------------------+
//				　インジケーター
//+------------------------------------------------------------------+

//9-2 フィルター|+DIと-DIの位置関係及びADXが一定値以上
int Indicator9_2(int i,ENUM_TIMEFRAMES TimeScale,int ADXper,double Val)
{
	 double CopyBuf1[];
	 ArraySetAsSeries(CopyBuf1,true);
	 int Handle1 = iADX(NULL,TimeScale,ADXper);
	 CopyBuffer( Handle1,1,0,iBars+300,CopyBuf1);
	 double Plus_DI=CopyBuf1[i];
	 
	 double CopyBuf2[];
	 ArraySetAsSeries(CopyBuf2,true);
	 CopyBuffer( Handle1,2,0,iBars+300,CopyBuf2);
	 double Minus_DI=CopyBuf2[i];
	 
	 double CopyBuf3[];
	 ArraySetAsSeries(CopyBuf3,true);
	 CopyBuffer( Handle1,0,0,iBars+300,CopyBuf3);
	 double ADX=CopyBuf3[i];
	 int ret=0;
	 if (Plus_DI>Minus_DI && ADX>Val)
	 {
		 ret=1;
	 }
	 else if (Plus_DI<Minus_DI && ADX>Val)
	 {
		 ret=-1;
	 }
	 return(ret);
}

//+------------------------------------------------------------------+
//				イニシャル処理
//+------------------------------------------------------------------+
void OnInit()
{
	 //テスターで表示されるインジケータを非表示にする
	 TesterHideIndicators(true); 

}

//+------------------------------------------------------------------+
//				ティック毎の処理
//+------------------------------------------------------------------+
void OnTick()
{
 
	 
	 //ブレークイーブン
	 static bool checkDone;
	 MqlDateTime tm;
	 TimeCurrent(tm);
	 int sec = tm.sec;
	 if(sec == 0 || sec == 10 || sec == 20|| sec == 30|| sec == 40|| sec == 50 )
	 {
		 if(checkDone==false)
		 {
		 BreakEvenStop();
		 checkDone = true;
		 }
	 }
	 else
	 {
		 checkDone = false;
	 }
	 
	 // ニューバーの発生直後以外は取引しない
	 datetime TimeArray[1]; 
	 CopyTime(_Symbol, _Period, 0, 1, TimeArray); 
	 if(TimeArray[0] == Time) return; 
	 Time = TimeArray[0];

	 checkDone = false;

	 //各種パラメーター取得
	 int EntryBuy=0;
	 int EntrySell=0;
	 int ExitBuy=0;
	 int ExitSell=0;
	 
	 int LongNum=LongPosition();
	 int ShortNum=ShortPosition();
	 
	 //クローズ判定
	 //買いのクローズロジックは選択されていません
	 //売りのクローズロジックは選択されていません

	 //エントリ基準取得
	 int Strtagy1=Indicator9_2(Entry1,TimeScale1,ADX1_period,ADX1_value);
	 int TotalNum=ShortNum+LongNum;
	 
	 //エントリ判定
	 if((TotalNum<MaxPosition && Strtagy1==1 ))
	 {
		 EntryBuy=1;
	 }
	 else
	 if((TotalNum<MaxPosition && Strtagy1==-1 ))
	 {
		 EntrySell=1;
	 }

	 //オープン処理
	 double Bid, Ask;
	 MqlTick tick;
	 SymbolInfoTick(_Symbol, tick);
	 Bid = tick.bid;
	 Ask = tick.ask;
	 
	 if( ((Ask-Bid)/AdjustPoint(_Symbol)) < MaxSpread )
	 {
		 if(EntryBuy!=0)
		 {
			 OpenOrder(1);
		 }
		 if(EntrySell!=0) 
		 {
			 OpenOrder(-1);
		 }
	 }
}
