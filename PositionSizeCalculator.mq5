//+------------------------------------------------------------------+
//|                                  PositionFactorCalculator.mq5    |
//|                                  Inspired by EarnForex's PSC     |
//+------------------------------------------------------------------+
#property copyright "Custom Breakout Factor Calculator"
#property version   "1.51"

#include <Controls\Dialog.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include <Controls\Panel.mqh>
#include <Controls\Button.mqh>
#include <Trade\Trade.mqh>

input color    UpperLineColor = clrGreen;   // Upper Line (Long) Color
input color    LowerLineColor = clrRed;     // Lower Line (Short) Color
input double   DefaultDistancePips = 10.0;  // Default Line Distance (Pips)

//--- UI Controls
CAppDialog     AppPanel;

// Run Toggle
CButton        BtnRun;
bool           IsTradingActive = false;
color          DefaultForegroundColor;

// Long Panel Elements (Green)
CPanel         PnlLong;
CLabel         LblLongTitle;
CLabel         LblLongVol;
CEdit          EdtLongVol;
CLabel         LblLongDist;
CEdit          EdtLongDist;
CLabel         LblLongMoney;
CEdit          EdtLongMoney;
CLabel         LblLongRisk;
CEdit          EdtLongRisk;

// Short Panel Elements (Red)
CPanel         PnlShort;
CLabel         LblShortTitle;
CLabel         LblShortVol;
CEdit          EdtShortVol;
CLabel         LblShortDist;
CEdit          EdtShortDist;
CLabel         LblShortMoney;
CEdit          EdtShortMoney;
CLabel         LblShortRisk;
CEdit          EdtShortRisk;

string Line_1 = "PSC_line_1";
string Line_2 = "PSC_line_2";

// Colors for the UI
color clrLongBG = C'220, 255, 220';  // Light Green
color clrShortBG = C'255, 220, 220'; // Light Red

// Trade Object
CTrade         TradeExt;
ulong          MagicNumber = 123456;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    DefaultForegroundColor = (color)ChartGetInteger(0, CHART_COLOR_FOREGROUND);
    TradeExt.SetExpertMagicNumber(MagicNumber);

    // 1. Create the Main UI Panel (W: 390, H: 340)
    // We increased the overall size so elements don't get clipped by the borders
    if(!AppPanel.Create(0, "Position Factor (Breakout)", 0, 20, 20, 410, 360))
        return INIT_FAILED;

    // RUN Button (x1: 10, y1: 10, x2: 370, y2: 40)
    if(!BtnRun.Create(0, "BtnRun", 0, 10, 10, 370, 40)) return INIT_FAILED;
    BtnRun.Text("RUN (Trading OFF)");
    BtnRun.ColorBackground(clrLightGray);
    BtnRun.Color(clrBlack);
    AppPanel.Add(BtnRun);

    // ==========================================
    // ============ LONG SECTION (GREEN) ========
    // ==========================================
    if(!PnlLong.Create(0, "PnlLong", 0, 10, 50, 185, 290)) return INIT_FAILED;
    PnlLong.ColorBackground(clrLongBG);
    AppPanel.Add(PnlLong);

    if(!LblLongTitle.Create(0, "LblLongTitle", 0, 20, 55, 175, 75)) return INIT_FAILED;
    LblLongTitle.Text("LONG (Upper Entry)");
    AppPanel.Add(LblLongTitle);

    // Volume (Editable)
    if(!LblLongVol.Create(0, "LblLongVol", 0, 20, 85, 175, 105)) return INIT_FAILED;
    LblLongVol.Text("Trade Volume (Lots):");
    AppPanel.Add(LblLongVol);
    if(!EdtLongVol.Create(0, "EdtLongVol", 0, 20, 105, 175, 125)) return INIT_FAILED;
    EdtLongVol.Text("1.00"); // Default 1 lot
    AppPanel.Add(EdtLongVol);

    // Distance (Read Only)
    if(!LblLongDist.Create(0, "LblLongDist", 0, 20, 135, 175, 155)) return INIT_FAILED;
    LblLongDist.Text("SL Distance (Pts):");
    AppPanel.Add(LblLongDist);
    if(!EdtLongDist.Create(0, "EdtLongDist", 0, 20, 155, 175, 175)) return INIT_FAILED;
    EdtLongDist.ReadOnly(true); EdtLongDist.ColorBackground(clrLongBG);
    AppPanel.Add(EdtLongDist);

    // Money Risk (Read Only)
    if(!LblLongMoney.Create(0, "LblLongMoney", 0, 20, 185, 175, 205)) return INIT_FAILED;
    LblLongMoney.Text("Money Risk ($):");
    AppPanel.Add(LblLongMoney);
    if(!EdtLongMoney.Create(0, "EdtLongMoney", 0, 20, 205, 175, 225)) return INIT_FAILED;
    EdtLongMoney.ReadOnly(true); EdtLongMoney.ColorBackground(clrLongBG);
    AppPanel.Add(EdtLongMoney);

    // Account Risk % (Read Only)
    if(!LblLongRisk.Create(0, "LblLongRisk", 0, 20, 235, 175, 255)) return INIT_FAILED;
    LblLongRisk.Text("Account Risk (%):");
    AppPanel.Add(LblLongRisk);
    if(!EdtLongRisk.Create(0, "EdtLongRisk", 0, 20, 255, 175, 275)) return INIT_FAILED;
    EdtLongRisk.ReadOnly(true); EdtLongRisk.ColorBackground(clrLongBG);
    AppPanel.Add(EdtLongRisk);


    // ==========================================
    // =========== SHORT SECTION (RED) ==========
    // ==========================================
    if(!PnlShort.Create(0, "PnlShort", 0, 195, 50, 370, 290)) return INIT_FAILED;
    PnlShort.ColorBackground(clrShortBG);
    AppPanel.Add(PnlShort);

    if(!LblShortTitle.Create(0, "LblShortTitle", 0, 205, 55, 360, 75)) return INIT_FAILED;
    LblShortTitle.Text("SHORT (Lower Entry)");
    AppPanel.Add(LblShortTitle);

    // Volume (Editable)
    if(!LblShortVol.Create(0, "LblShortVol", 0, 205, 85, 360, 105)) return INIT_FAILED;
    LblShortVol.Text("Trade Volume (Lots):");
    AppPanel.Add(LblShortVol);
    if(!EdtShortVol.Create(0, "EdtShortVol", 0, 205, 105, 360, 125)) return INIT_FAILED;
    EdtShortVol.Text("1.00"); // Default 1 lot
    AppPanel.Add(EdtShortVol);

    // Distance (Read Only)
    if(!LblShortDist.Create(0, "LblShortDist", 0, 205, 135, 360, 155)) return INIT_FAILED;
    LblShortDist.Text("SL Distance (Pts):");
    AppPanel.Add(LblShortDist);
    if(!EdtShortDist.Create(0, "EdtShortDist", 0, 205, 155, 360, 175)) return INIT_FAILED;
    EdtShortDist.ReadOnly(true); EdtShortDist.ColorBackground(clrShortBG);
    AppPanel.Add(EdtShortDist);

    // Money Risk (Read Only)
    if(!LblShortMoney.Create(0, "LblShortMoney", 0, 205, 185, 360, 205)) return INIT_FAILED;
    LblShortMoney.Text("Money Risk ($):");
    AppPanel.Add(LblShortMoney);
    if(!EdtShortMoney.Create(0, "EdtShortMoney", 0, 205, 205, 360, 225)) return INIT_FAILED;
    EdtShortMoney.ReadOnly(true); EdtShortMoney.ColorBackground(clrShortBG);
    AppPanel.Add(EdtShortMoney);

    // Account Risk % (Read Only)
    if(!LblShortRisk.Create(0, "LblShortRisk", 0, 205, 235, 360, 255)) return INIT_FAILED;
    LblShortRisk.Text("Account Risk (%):");
    AppPanel.Add(LblShortRisk);
    if(!EdtShortRisk.Create(0, "EdtShortRisk", 0, 205, 255, 360, 275)) return INIT_FAILED;
    EdtShortRisk.ReadOnly(true); EdtShortRisk.ColorBackground(clrShortBG);
    AppPanel.Add(EdtShortRisk);

    AppPanel.Run();

    // 2. Drop the two editable lines onto the chart
    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    // Auto-calculate pip size
    double pip_size = (digits == 3 || digits == 5) ? (point * 10.0) : point;
    double half_distance = (DefaultDistancePips * pip_size) / 2.0;
    
    if(ObjectFind(0, Line_1) < 0) {
        ObjectCreate(0, Line_1, OBJ_HLINE, 0, 0, current_price + half_distance);
        ObjectSetInteger(0, Line_1, OBJPROP_COLOR, UpperLineColor);
        ObjectSetInteger(0, Line_1, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0, Line_1, OBJPROP_SELECTED, true);
        ObjectSetInteger(0, Line_1, OBJPROP_WIDTH, 2);
    }
    
    if(ObjectFind(0, Line_2) < 0) {
        ObjectCreate(0, Line_2, OBJ_HLINE, 0, 0, current_price - half_distance);
        ObjectSetInteger(0, Line_2, OBJPROP_COLOR, LowerLineColor);
        ObjectSetInteger(0, Line_2, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0, Line_2, OBJPROP_SELECTED, true);
        ObjectSetInteger(0, Line_2, OBJPROP_WIDTH, 2);
    }

    CalculateFactor();
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    AppPanel.Destroy(reason);
    ObjectDelete(0, Line_1);
    ObjectDelete(0, Line_2);
    ChartSetInteger(0, CHART_COLOR_FOREGROUND, DefaultForegroundColor);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    CalculateFactor();
    CheckTradeLogic();
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    AppPanel.ChartEvent(id, lparam, dparam, sparam);
    
    // Check RUN Button Click
    if(id == CHARTEVENT_CUSTOM + ON_CLICK)
    {
        if(sparam == BtnRun.Name()) 
        {
            IsTradingActive = !IsTradingActive;
            if(IsTradingActive) {
                BtnRun.Text("STOP (Trading ON)");
                BtnRun.ColorBackground(clrGold); // Turn button Gold so you know it's active
                ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrYellow);
            } else {
                BtnRun.Text("RUN (Trading OFF)");
                BtnRun.ColorBackground(clrLightGray);
                ChartSetInteger(0, CHART_COLOR_FOREGROUND, DefaultForegroundColor);
            }
            ChartRedraw();
        }
        else // Other edits (Volume changes, etc)
        {
            CalculateFactor();
            ChartRedraw();
        }
    }
    
    // Recalculate whenever lines are dragged
    if(id == CHARTEVENT_OBJECT_DRAG)
    {
        CalculateFactor();
        ChartRedraw();
    }
}

//+------------------------------------------------------------------+
//| Trade Execution Logic                                            |
//+------------------------------------------------------------------+
void CheckTradeLogic()
{
    if(!IsTradingActive) return;

    double p1 = ObjectGetDouble(0, Line_1, OBJPROP_PRICE);
    double p2 = ObjectGetDouble(0, Line_2, OBJPROP_PRICE);
    
    double upper_price = MathMax(p1, p2);
    double lower_price = MathMin(p1, p2);

    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    // Do not span orders if an order or position is already active for this strategy
    bool activeTradesExist = false;
    
    for(int i = OrdersTotal() - 1; i >= 0; i--) {
        ulong ticket = OrderGetTicket(i);
        if(OrderGetInteger(ORDER_MAGIC) == MagicNumber) activeTradesExist = true;
    }
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(PositionGetInteger(POSITION_MAGIC) == MagicNumber) activeTradesExist = true;
    }

    if(activeTradesExist) return; // Wait until trades hit SL/TP or are closed manually

    double short_vol = StringToDouble(EdtShortVol.Text());
    double long_vol = StringToDouble(EdtLongVol.Text());

    // Logic 1: Price goes bigger than upper line -> Sell Stop at lower line (SL = upper line)
    if(bid > upper_price) {
        if(short_vol > 0) {
            TradeExt.SellStop(short_vol, lower_price, _Symbol, upper_price, 0, ORDER_TIME_GTC, 0, "PSC Breakout Short");
        }
    }
    // Logic 2: Price goes less than lower line -> Buy Stop at upper line (SL = lower line)
    else if(ask < lower_price) {
        if(long_vol > 0) {
            TradeExt.BuyStop(long_vol, upper_price, _Symbol, lower_price, 0, ORDER_TIME_GTC, 0, "PSC Breakout Long");
        }
    }
}

//+------------------------------------------------------------------+
//| Core Position Factor Logic                                       |
//+------------------------------------------------------------------+
void CalculateFactor()
{
    double p1 = ObjectGetDouble(0, Line_1, OBJPROP_PRICE);
    double p2 = ObjectGetDouble(0, Line_2, OBJPROP_PRICE);
    
    double upper_price = MathMax(p1, p2);
    double lower_price = MathMin(p1, p2);
    
    if(p1 > p2) {
        ObjectSetInteger(0, Line_1, OBJPROP_COLOR, UpperLineColor);
        ObjectSetInteger(0, Line_2, OBJPROP_COLOR, LowerLineColor);
    } else if (p2 > p1) {
        ObjectSetInteger(0, Line_1, OBJPROP_COLOR, LowerLineColor);
        ObjectSetInteger(0, Line_2, OBJPROP_COLOR, UpperLineColor);
    }
    
    double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    if(tick_size == 0 || tick_value == 0 || point == 0) return;
    
    double distance = upper_price - lower_price;
    int points_distance = (int)MathRound(distance / point);
    
    string str_points = IntegerToString(points_distance);
    EdtLongDist.Text(str_points);
    EdtShortDist.Text(str_points);
    
    if(distance <= 0) {
        EdtLongMoney.Text("0.00");
        EdtShortMoney.Text("0.00");
        EdtLongRisk.Text("0.00%");
        EdtShortRisk.Text("0.00%");
        return;
    }
    
    double risk_per_lot = (distance / tick_size) * tick_value;
    
    double long_vol = StringToDouble(EdtLongVol.Text());
    double short_vol = StringToDouble(EdtShortVol.Text());
    if (long_vol < 0) long_vol = 0;
    if (short_vol < 0) short_vol = 0;

    double long_money = long_vol * risk_per_lot;
    double short_money = short_vol * risk_per_lot;
    
    EdtLongMoney.Text(DoubleToString(long_money, 2));
    EdtShortMoney.Text(DoubleToString(short_money, 2));
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    if(balance > 0) {
        double long_risk_pct = (long_money / balance) * 100.0;
        double short_risk_pct = (short_money / balance) * 100.0;
        
        EdtLongRisk.Text(DoubleToString(long_risk_pct, 2) + " %");
        EdtShortRisk.Text(DoubleToString(short_risk_pct, 2) + " %");
    }
}
//+------------------------------------------------------------------+