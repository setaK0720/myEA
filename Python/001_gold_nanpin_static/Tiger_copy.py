# %% [markdown]
# Python用MetaTrader5のインポート

# %%
import MetaTrader5 as mt5
from datetime import datetime as dt
import pandas as pd

# coding: utf-8
import configparser
import os
import errno

# %% [markdown]
# ログイン情報を入力


Account_ini = configparser.ConfigParser()
Account_ini_path = r'AccountInfo.ini'
parameter_ini = configparser.ConfigParser()
parameter_ini_path = r'ea_parameter.ini'

if not os.path.exists(Account_ini_path):
    raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), Account_ini_path)
Account_ini.read(Account_ini_path,encoding="utf-8")

if not os.path.exists(parameter_ini_path):
    raise FileNotFoundError(errno.ENOENT, os.strerror(errno.ENOENT), parameter_ini_path)
parameter_ini.read(parameter_ini_path,encoding="utf-8")

# %%
login_ID = Account_ini.getint('DEFAULT','AccountId') # ご自身のログインIDを入力
login_server = Account_ini.get('DEFAULT','Server') # ご自身のログインサーバーを入力
login_password = Account_ini.get('DEFAULT','Password') # ご自身のログインパスワードを入力
AccountNumber = str(login_ID)


# %% [markdown]
# MT5に接続

# %%
# ログイン情報で指定した取引口座でMetaTrader5に接続
if not mt5.initialize(login=login_ID, server=login_server,password=login_password):
    print("initialize() failed, error code =",mt5.last_error())
    quit()

# %%


# %% [markdown]
# Input設定

# %%
symbol    = parameter_ini.get('DEFAULT', 'symbol')
first_lot = parameter_ini.getfloat('DEFAULT', 'first_lot')
nanpin_range = parameter_ini.getint('DEFAULT', 'nanpin_range')
position_limit = parameter_ini.getint('DEFAULT', 'position_limit')
nanpin_mode = parameter_ini.get('DEFAULT', 'nanpin_mode')
martin_lot = parameter_ini.getfloat('DEFAULT', 'martin_lot')
addition_lot = parameter_ini.getfloat('DEFAULT', 'addition_lot')
profit_mode = parameter_ini.get('DEFAULT', 'profit_mode')
profit_pips = parameter_ini.getint('DEFAULT', 'profit_pips')
magic_number = parameter_ini.getint('DEFAULT', 'magic_number')
slippage = parameter_ini.getint('DEFAULT', 'slippage')
spread_limit = parameter_ini.getint('DEFAULT', 'spread_limit')
open_time = parameter_ini.getint('DEFAULT', 'open_time')
close_time = parameter_ini.getint('DEFAULT', 'close_time')

pip_value = parameter_ini.getint('DEFAULT', 'pip_value')
point = parameter_ini.getfloat('DEFAULT', 'point')





# %% [markdown]
# 各種情報取得

# %%
point=mt5.symbol_info(symbol).point # 価格の最小単位

# %% [markdown]
# ループ処理
# %% [markdown]
# エントリー時間設定

# %%

# %%
while 1:
    


    if open_time < dt.now().hour & dt.now().hour < close_time :
        entry_time = True
    else :
        entry_time = False

       
    symbol_tick=mt5.symbol_info_tick(symbol) # symbolのtick情報を取得

    
    #### ポジションの確認###########################################
    
    buy_position = 0 # buyポジション数の初期化
    sell_position = 0 # sellポジション数の初期化
    buy_profit = 0 # buy_profitの初期化
    sell_profit = 0 # sell_profitの初期化
    current_buy_lot = 0 # 最新のbuyポジションのlot数の初期化
    current_sell_lot = 0 # 最新のsellポジションのlot数の初期化
    total_buy_price = 0 # 現在のbuyポジションの合計価格（平均取得単価計算用）
    total_sell_price = 0 # 現在のsellポジションの合計価格（平均取得単価計算用）
    total_buy_lot = 0 # buyポジションの合計lot
    total_sell_lot = 0 # sellポジションの合計lot

    positions=mt5.positions_get(group='*'+symbol+'*') # ポジション情報を取得
    
    for i in range(len(positions)): # 全てのポジションを確認
        order_type = positions[i][5] # buyかsellか取得
        profit = positions[i][15] # ポジションの含み損益を取得
        
        if order_type == 0: # buyポジションの場合
            buy_position += 1 # buyポジションのカウント
            buy_profit += profit # buyポジションの含み損益に加算
            current_buy_lot = positions[i][9] # 最新のbuyポジションのlot数を取得
            current_buy_price = positions[i][10] # 最新のbuyポジションの取得価格を取得
            total_buy_price = total_buy_price + current_buy_price * current_buy_lot # buyポジションの合計価格を取得
            total_buy_lot = total_buy_lot + current_buy_lot # buyポジションの合計lot数を取得
            getAverageOpenPrice_buy = total_buy_price / total_buy_lot # buyポジションの平均取得単価を計算
            
        if order_type == 1: # sellポジションの場合
            sell_position += 1 # sellポジションのカウント
            sell_profit += profit # sellポジションの含み損益に加算
            current_sell_lot = positions[i][9] # 最新のsellポジションのlot数を取得
            current_sell_price = positions[i][10] # 最新のsellポジションの取得価格を取得
            total_sell_price = total_sell_price + current_sell_price * current_sell_lot # sellポジションの合計価格を取得
            total_sell_lot = total_sell_lot + current_sell_lot # sellポジションの合計lot数を取得
            getAverageOpenPrice_sell = total_sell_price / total_sell_lot # sellポジションの平均取得単価を計算
    ################################################################
    
    
    #### 新規buyエントリー###########################################
            
    if buy_position == 0 and entry_time == True : # buyポジションがない&新規エントリー可能時間内

        request = {
                    'symbol': symbol, # 通貨ペア（取引対象）
                    'action': mt5.TRADE_ACTION_DEAL, # 成行注文
                    'type': mt5.ORDER_TYPE_BUY, # 成行買い注文
                    'volume': first_lot, # ロット数
                    'price': symbol_tick.ask, # 注文価格
                    'deviation': slippage, # スリッページ
                    'comment': 'first_buy', # 注文コメント
                    'magic': magic_number, # マジックナンバー
                    'type_time': mt5.ORDER_TIME_GTC, # 注文有効期限
                    'type_filling': mt5.ORDER_FILLING_IOC, # 注文タイプ
                    }

        result = mt5.order_send(request)
    
    ################################################################
    
    
    #### 新規sellエントリー###########################################
    
    if sell_position == 0 and entry_time == True: # sellポジションがない&新規エントリー可能時間内

        request = {
                    'symbol': symbol, # 通貨ペア（取引対象）
                    'action': mt5.TRADE_ACTION_DEAL, # 成行注文
                    'type': mt5.ORDER_TYPE_SELL, # 成行買い注文
                    'volume': first_lot, # ロット数
                    'price': symbol_tick.bid, # 注文価格
                    'deviation': slippage, # スリッページ
                    'comment': 'first_sell', # 注文コメント
                    'magic': magic_number, # マジックナンバー
                    'type_time': mt5.ORDER_TIME_GTC, # 注文有効期限
                    'type_filling': mt5.ORDER_FILLING_IOC, # 注文タイプ
                    }

        result = mt5.order_send(request)

    ################################################################
    
    
    #### 追加buyエントリー###########################################
    
    if buy_position > 0 and symbol_tick.ask < current_buy_price - nanpin_range * point:
        entry_lot = round(current_buy_lot * martin_lot,2)
        request = {
                    'symbol': symbol, # 通貨ペア（取引対象）
                    'action': mt5.TRADE_ACTION_DEAL, # 成行注文
                    'type': mt5.ORDER_TYPE_BUY, # 成行買い注文
                    'volume': entry_lot, # ロット数
                    'price': symbol_tick.ask, # 注文価格
                    'deviation': slippage, # スリッページ
                    'comment': 'nanpin_buy', # 注文コメント
                    'magic': magic_number, # マジックナンバー
                    'type_time': mt5.ORDER_TIME_GTC, # 注文有効期限
                    'type_filling': mt5.ORDER_FILLING_IOC, # 注文タイプ
                    }

        result = mt5.order_send(request)

    ##################################################################
    
    
    #### 追加sellエントリー###########################################
    
    if sell_position > 0 and symbol_tick.bid > current_sell_price + nanpin_range * point:
        entry_lot = round(current_buy_lot * martin_lot,2)

        request = {
                    'symbol': symbol, # 通貨ペア（取引対象）
                    'action': mt5.TRADE_ACTION_DEAL, # 成行注文
                    'type': mt5.ORDER_TYPE_SELL, # 成行売り注文
                    'volume': entry_lot, # ロット数
                    'price': symbol_tick.bid, # 注文価格
                    'deviation': slippage, # スリッページ
                    'comment': 'nanpin_sell', # 注文コメント
                    'magic': magic_number, # マジックナンバー
                    'type_time': mt5.ORDER_TIME_GTC, # 注文有効期限
                    'type_filling': mt5.ORDER_FILLING_IOC, # 注文タイプ
                    }

        result = mt5.order_send(request)

    ##################################################################
    
    
    #### buyクローズ##################################################
    
    if buy_position > 0 and getAverageOpenPrice_buy + profit_pips * 0.01 < symbol_tick.bid :

        for i in range(len(positions)):
            ticket=positions[i][0] # チケットナンバーを取得
            order_type = positions[i][5] # buyかsellか取得
            lot = positions[i][9] # lot数を取得

            if order_type == 0: # buyポジションをクローズ
                request = {
                            'symbol': symbol, # 通貨ペア（取引対象）
                            'action': mt5.TRADE_ACTION_DEAL, # 成行注文
                            'type': mt5.ORDER_TYPE_SELL, # 成行売り注文
                            'volume': lot, # ロット数
                            'price': symbol_tick.bid, # 注文価格
                            'deviation': slippage, # スリッページ
                            'type_time': mt5.ORDER_TIME_GTC, # 注文有効期限
                            'type_filling': mt5.ORDER_FILLING_IOC, # 注文タイプ
                            'position':ticket # チケットナンバー
                            }
                result = mt5.order_send(request)


    ##################################################################
    
    
    #### sellクローズ#################################################
    
    if sell_position > 0 and getAverageOpenPrice_sell - profit_pips * 0.01> symbol_tick.ask :
    
        for i in range(len(positions)):
            ticket=positions[i][0] # チケットナンバーを取得
            order_type = positions[i][5] # buyかsellか取得
            lot = positions[i][9] # lot数を取得

            if order_type == 1: # sellポジションをクローズ
                request = {
                            'symbol': symbol, # 通貨ペア（取引対象）
                            'action': mt5.TRADE_ACTION_DEAL, # 成行注文
                            'type': mt5.ORDER_TYPE_BUY, # 成行買い注文
                            'volume': lot, # ロット数
                            'price': symbol_tick.ask, # 注文価格
                            'deviation': slippage, # スリッページ
                            'type_time': mt5.ORDER_TIME_GTC, # 注文有効期限
                            'type_filling': mt5.ORDER_FILLING_IOC, # 注文タイプ
                            'position':ticket # チケットナンバー
                            }
                result = mt5.order_send(request)

    ##################################################################



# %%
