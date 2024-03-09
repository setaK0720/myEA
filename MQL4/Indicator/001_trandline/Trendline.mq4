//+------------------------------------------------------------------+
//|                                                   trend_line.mq4 |
//|                                     Copyright 2021,こっこの趣味ブログ |
//|                                           http://www.kocco36.xyz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021,こっこの趣味ブログ"
#property link      "http://www.kocco36.xyz"
#property version   "1.00"
#property strict
#property indicator_chart_window

string obj_name_high = "trend_line_high";
string obj_name_low = "trend_line_low";


int OnInit()
{   
   return(INIT_SUCCEEDED);
}

int deinit()
{
   ObjectDelete(obj_name_high);
   ObjectDelete(obj_name_low);

   return(0);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{   
   //一度オブジェクト削除
   ObjectDelete(obj_name_high);
   ObjectDelete(obj_name_low);
   
   //上のトレンドライン
   int first_high_index = iHighest(Symbol(), Period(), MODE_HIGH, 60, 0);
   double first_high_top = iHigh(Symbol(), Period(), first_high_index);
   
   int second_high = first_high_index - 30;
   if(0 <= second_high)
   {
      int second_high_index = iHighest(Symbol(), Period(), MODE_HIGH, 30, 0);
      double second_high_price = iHigh(Symbol(), Period(), second_high_index);
   
      ObjectCreate(0, obj_name_high, OBJ_TREND, 0, Time[first_high_index], first_high_top, Time[second_high_index], second_high_price);
      ObjectSetInteger(0, obj_name_high, OBJPROP_COLOR, clrYellow);   //オブジェクトカラー設定
      ObjectSetInteger(0, obj_name_high, OBJPROP_STYLE, STYLE_SOLID); //オブジェクトラインスタイル設定
      ObjectSetInteger(0, obj_name_high, OBJPROP_WIDTH, 1);           //オブジェクトラインの太さ設定
   }
   
   
   int first_low_index = iLowest(Symbol(), Period(), MODE_LOW, 60, 0);
   double first_low_top = iLow(Symbol(), Period(), first_low_index);
   
   int second_low = first_low_index - 30;
   if(0 <= second_low)
   {
      int second_low_index = iLowest(Symbol(), Period(), MODE_LOW, 30, 0);
      double second_low_price = iLow(Symbol(), Period(), second_low_index);
   
      ObjectCreate(0, obj_name_low, OBJ_TREND, 0, Time[first_low_index], first_low_top, Time[second_low_index], second_low_price);
      ObjectSetInteger(0, obj_name_low, OBJPROP_COLOR, clrYellow);   //オブジェクトカラー設定
      ObjectSetInteger(0, obj_name_low, OBJPROP_STYLE, STYLE_SOLID); //オブジェクトラインスタイル設定
      ObjectSetInteger(0, obj_name_low, OBJPROP_WIDTH, 1);           //オブジェクトラインの太さ設定
   }
   return(rates_total);

   
}