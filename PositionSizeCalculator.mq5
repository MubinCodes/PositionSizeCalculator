//+------------------------------------------------------------------+
//| PositionSizeCalculator.mq5                                       |
//| MetaTrader 5 Position Size Calculator Dashboard                  |
//| Author: MubinCodes                                               |
//| GitHub: https://github.com/MubinCodes                            |
//|                                                                  |
//| This EA provides a chart-based position size calculator.          |
//| Users can enter symbol, risk percentage, and stop loss in pips    |
//| to calculate lot size quickly.                                   |
//|                                                                  |
//| Disclaimer: This project is for educational and portfolio         |
//| demonstration purposes only. Trading involves risk.               |
//+------------------------------------------------------------------+
#property copyright "MubinCodes"
#property link      "https://github.com/MubinCodes"
#property version   "1.00"
#property strict

//-------------------- Inputs --------------------
input bool   UseEquityForCalculation = true;   // Use equity instead of balance
input string DefaultSymbol           = "";     // Empty = current chart symbol
input double DefaultRiskPercent      = 1.00;   // Default Risk (%)
input double DefaultStopLossPips     = 50.0;   // Default Stop Loss Pips

input int    PanelX                  = 20;
input int    PanelY                  = 30;

//-------------------- Global --------------------
string Prefix = "PSC_DASH_";

int PanelW = 390;
int PanelH = 335;

string ObjPanel;
string ObjTitle;
string ObjSource;
string ObjSymbolLabel;
string ObjSymbolEdit;
string ObjRiskLabel;
string ObjRiskEdit;
string ObjSLLabel;
string ObjSLEdit;
string ObjCalculateBtn;
string ObjResultLot;
string ObjResultRiskMoney;
string ObjResultLossOneLot;
string ObjStatus;

//+------------------------------------------------------------------+
//| Expert initialization                                             |
//+------------------------------------------------------------------+
int OnInit()
{
   ObjPanel            = Prefix + "Panel";
   ObjTitle            = Prefix + "Title";
   ObjSource           = Prefix + "Source";
   ObjSymbolLabel      = Prefix + "SymbolLabel";
   ObjSymbolEdit       = Prefix + "SymbolEdit";
   ObjRiskLabel        = Prefix + "RiskLabel";
   ObjRiskEdit         = Prefix + "RiskEdit";
   ObjSLLabel          = Prefix + "SLLabel";
   ObjSLEdit           = Prefix + "SLEdit";
   ObjCalculateBtn     = Prefix + "CalculateBtn";
   ObjResultLot        = Prefix + "ResultLot";
   ObjResultRiskMoney  = Prefix + "ResultRiskMoney";
   ObjResultLossOneLot = Prefix + "ResultLossOneLot";
   ObjStatus           = Prefix + "Status";

   CreatePanel();
   CalculateAndDisplay();

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DeletePanelObjects();
}

//+------------------------------------------------------------------+
//| Expert tick                                                       |
//+------------------------------------------------------------------+
void OnTick()
{
   // No automatic trading.
   // This EA is only a position size calculator.
}

//+------------------------------------------------------------------+
//| Chart event                                                       |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == ObjCalculateBtn)
      {

         ResetButton(ObjCalculateBtn);
         CalculateAndDisplay();
         
         
         ChartRedraw();
      }
   }

   if(id == CHARTEVENT_OBJECT_ENDEDIT)
   {
      if(sparam == ObjSymbolEdit || sparam == ObjRiskEdit || sparam == ObjSLEdit)
      {
         CalculateAndDisplay();
         ChartRedraw();
      }
   }
}

//+------------------------------------------------------------------+
//| Create panel                                                      |
//+------------------------------------------------------------------+
void CreatePanel()
{
   DeletePanelObjects();

   int x = PanelX;
   int y = PanelY;

   CreateRect(ObjPanel, x, y, PanelW, PanelH, C'15,23,32', C'70,85,100');

   CreateLabel(ObjTitle, x + 20, y + 18, "Position Size Calculator", 15, clrWhite);

   string sourceText = "Source: ";
   sourceText += UseEquityForCalculation ? "Equity" : "Balance";
   CreateLabel(ObjSource, x + 20, y + 50, sourceText, 10, C'170,180,190');

   CreateRect(Prefix + "InputBox", x + 15, y + 80, PanelW - 30, 145, C'21,31,43', C'55,70,85');

   string symbolDefault = DefaultSymbol;
   StringTrimLeft(symbolDefault);
   StringTrimRight(symbolDefault);
   
   // If input is empty or accidentally shows 0, use current chart symbol
   if(symbolDefault == "" || symbolDefault == "0")
      symbolDefault = ChartSymbol(0);

   CreateLabel(ObjSymbolLabel, x + 30, y + 100, "Instrument", 10, clrWhite);
   CreateEdit(ObjSymbolEdit, x + 195, y + 92, 140, 28, symbolDefault);

   CreateLabel(ObjRiskLabel, x + 30, y + 140, "Risk (%)", 10, clrWhite);
   CreateEdit(ObjRiskEdit, x + 195, y + 132, 140, 28, DoubleToString(DefaultRiskPercent, 2));

   CreateLabel(ObjSLLabel, x + 30, y + 180, "Stop Loss (pips)", 10, clrWhite);
   CreateEdit(ObjSLEdit, x + 195, y + 172, 140, 28, DoubleToString(DefaultStopLossPips, 1));

   CreateButton(ObjCalculateBtn, x + 15, y + 240, PanelW - 30, 38, "CALCULATE LOT SIZE", C'45,120,200', clrWhite, 10);

   CreateLabel(ObjResultLot, x + 20, y + 290, "Calculated Lot: --", 13, clrLime);
   //CreateLabel(ObjResultRiskMoney, x + 20, y + 315, "Risk Amount: --", 9, C'190,200,210');
   //CreateLabel(ObjResultLossOneLot, x + 190, y + 315, "Loss/1 Lot: --", 9, C'190,200,210');

   CreateLabel(ObjStatus, x + 20, y + PanelH - 22, "Ready", 8, C'160,255,160');

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Calculate and display                                             |
//+------------------------------------------------------------------+
void CalculateAndDisplay()
{
   string symbol = ObjectGetString(0, ObjSymbolEdit, OBJPROP_TEXT);
   

   double riskPercent = GetEditDouble(ObjRiskEdit);
   double stopLossPips = GetEditDouble(ObjSLEdit);
   
   


   ClearResults();

   if(symbol == "")
   {
      SetStatus("Invalid instrument name.", clrRed);
      return;
   }

   if(!SymbolSelect(symbol, true))
   {
      SetStatus("Symbol not found: " + symbol, clrRed);
      return;
   }

   if(riskPercent <= 0.0)
   {
      SetStatus("Risk % must be greater than 0.", clrRed);
      return;
   }

   if(stopLossPips <= 0.0)
   {
      SetStatus("Stop Loss pips must be greater than 0.", clrRed);
      return;
   }

   double lotSize = CalculateLotSize(stopLossPips, riskPercent, symbol);

   if(lotSize <= 0.0)
   {
      SetStatus("Calculated lot is invalid.", clrRed);
      return;
   }

   ObjectSetString(0, ObjResultLot, OBJPROP_TEXT,
                   "Calculated Lot: " + DoubleToString(lotSize, GetLotDigits(symbol)));


   SetStatus("Calculated for " + symbol, C'160,255,160');
}

//+------------------------------------------------------------------+
//| Clear result text                                                 |
//+------------------------------------------------------------------+
void ClearResults()
{
   ObjectSetString(0, ObjResultLot, OBJPROP_TEXT, "Calculated Lot: --");
   ObjectSetString(0, ObjResultRiskMoney, OBJPROP_TEXT, "Risk Amount: --");
   ObjectSetString(0, ObjResultLossOneLot, OBJPROP_TEXT, "Loss/1 Lot: --");
}






//+------------------------------------------------------------------+
//| Get lot digits                                                    |
//+------------------------------------------------------------------+
int GetLotDigits(string symbol)
{
   double stepLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

   int digits = 0;

   while(stepLot < 1.0 && digits < 8)
   {
      stepLot *= 10.0;
      digits++;
   }

   return digits;
}

//+------------------------------------------------------------------+
//| Get edit box value as double                                      |
//+------------------------------------------------------------------+
double GetEditDouble(string name)
{
   string txt = ObjectGetString(0, name, OBJPROP_TEXT);
   return StringToDouble(txt);
}


//+------------------------------------------------------------------+
//| Get edit box value as double                                      |
//+------------------------------------------------------------------+
double GetSymbol(string name)
{
   string txt = ObjectGetString(0, name, OBJPROP_TEXT);
   return txt;
}

//+------------------------------------------------------------------+
//| Set status text                                                   |
//+------------------------------------------------------------------+
void SetStatus(string text, color clr)
{
   ObjectSetString(0, ObjStatus, OBJPROP_TEXT, text);
   ObjectSetInteger(0, ObjStatus, OBJPROP_COLOR, clr);
}

//+------------------------------------------------------------------+
//| Create rectangle                                                  |
//+------------------------------------------------------------------+
void CreateRect(string name, int x, int y, int w, int h, color bg, color border)
{
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, border);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
}

//+------------------------------------------------------------------+
//| Create label                                                      |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, int fontSize, color textColor)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 2);
}

//+------------------------------------------------------------------+
//| Create edit box                                                   |
//+------------------------------------------------------------------+
void CreateEdit(string name, int x, int y, int w, int h, string text)
{
   ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, C'10,16,23');
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'75,90,105');
   ObjectSetInteger(0, name, OBJPROP_READONLY, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 3);
}

//+------------------------------------------------------------------+
//| Create button                                                     |
//+------------------------------------------------------------------+
void CreateButton(string name, int x, int y, int w, int h, string text, color bg, color textColor, int fontSize)
{
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrBlack);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 4);
}

//+------------------------------------------------------------------+
//| Reset button state                                                |
//+------------------------------------------------------------------+
void ResetButton(string name)
{
   ObjectSetInteger(0, name, OBJPROP_STATE, false);
}

//+------------------------------------------------------------------+
//| Delete panel objects                                              |
//+------------------------------------------------------------------+
void DeletePanelObjects()
{
   int total = ObjectsTotal(0, -1, -1);

   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, -1, -1);

      if(StringFind(name, Prefix) == 0)
         ObjectDelete(0, name);
   }
}




double CalculateLotSize(double stopLossPip, double maxRiskPerTrade, string symbol)
{
   // Calculate the position size.
   double LotSize = 0;
   
   // Get the value of a tick.
   double nTickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   
   // Normalize tick value if necessary.
   if ((Digits() == 3) || (Digits() == 5) || (Digits() == 2)){
      nTickValue = nTickValue * 10;
   }
   
   // Calculate the position size.
   LotSize = (AccountInfoDouble(ACCOUNT_BALANCE) * maxRiskPerTrade / 100) / (stopLossPip * nTickValue);
   
   // Round the lot size to the nearest lot step.
   LotSize = MathRound(LotSize / SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP)) * SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   
   return LotSize;
}
