class SUBWINDOW
{
private:
#define FILENAME (__FILE__ + ".tpl")
#define PATH "\\Files\\"

  static string TemplateToString( const long Chart_ID = 0, const string FileName = FILENAME )
  {
    short Data[];

    return((::ChartSaveTemplate(Chart_ID, PATH + FileName) && (::FileLoad(FileName, Data) > 0)) ?
           ::ShortArrayToString(Data) : NULL);
  }

  static bool TemplateApply( const long Chart_ID, const string &Str, const string FileName = FILENAME )
  {
    short Data[];
    const bool Res = ::StringToShortArray(Str, Data, 0, ::StringLen(Str)) &&
                     ::FileSave(FileName, Data) && ::ChartApplyTemplate(Chart_ID, PATH + FileName);

    return(Res);
  }

#undef PATH
#undef FILENAME

  template <typename T>
  static bool Swap( T &Value1, T &Value2 )
  {
    const T Tmp = Value1;

    Value1 = Value2;
    Value2 = Tmp;

    return(true);
  }

  template <typename T>
  static int DeleteElement( T &Array[], const uint Index )
  {
    const int Size = ::ArraySize(Array);

    for (int i = (int)Index; i < Size - 1; i++)
      Array[i] = Array[i + 1];

    return(::ArrayResize(Array, Size - 1));
  }

  template <typename T>
  static int AddElement( T &Array[], T Value, const uint Index ) // https://www.mql5.com/ru/forum/1111/page2022#comment_5755426
  {
    const int Size = ::ArrayResize(Array, ::ArraySize(Array) + 1);

    const int j = (int)((Index < (uint)Size) ? Index : Size - 1);

    for (int i = Size - 1; i > j; i--)
      Array[i] = Array[i - 1];

    Array[j] = Value;

    return(Size);
  }

  static string StringBetween( string &Str, const string StrBegin, const string StrEnd = NULL )
  {
    int PosBegin = ::StringFind(Str, StrBegin);
    PosBegin = (PosBegin >= 0) ? PosBegin : 0;

    int PosEnd = ::StringFind(Str, StrEnd, PosBegin + ::StringLen(StrBegin));

    PosEnd = (PosEnd >= 0) ? PosEnd + ::StringLen(StrEnd) : -1;

    const string Res = ::StringSubstr(Str, PosBegin, (PosEnd >= 0) ? PosEnd - PosBegin : -1);
    Str = (PosEnd >= 0) ? ::StringSubstr(Str, PosEnd) : NULL;

    if (Str == "")
      Str = NULL;

    return(Res);
  }

  static int GetSubWindows( const long Chart_ID, string &StrBegin, string &SubWindows[], string &StrEnd )
  {
    StrEnd = SUBWINDOW::TemplateToString(Chart_ID);

    const int Total = ::ArrayResize(SubWindows, (StrEnd != NULL) ? (int)::ChartGetInteger(Chart_ID, CHART_WINDOWS_TOTAL) : 0);

    StrBegin = SUBWINDOW::StringBetween(StrEnd, NULL, "<window>");

    for (int i = 0; i < Total; i++)
      SubWindows[i] = SUBWINDOW::StringBetween(StrEnd, NULL, "</window>");

    return(Total);
  }

  static bool SetSubWindows( const long Chart_ID, const string &StrBegin, const string &SubWindows[], const string &StrEnd )
  {
    const int Size = ::ArraySize(SubWindows);

    string StrTemplate = StrBegin;

    for (int i = 0; i < Size; i++)
      StrTemplate += SubWindows[i];

    StrTemplate += StrEnd;

    return(SUBWINDOW::TemplateApply(Chart_ID, StrTemplate));
  }

public:
  // Получение индекса подокна чарта по координатам
  static int Get( const long Chart_ID, const int X, const int Y )
  {
    int SubWindow = 0;
    datetime time;
    double Price;

    ::ChartXYToTimePrice(Chart_ID, X, Y, SubWindow, time, Price);

    return(SubWindow);
  }

#define SUBWINDOW_MACROS(A,B)                                                        \
  {                                                                                  \
    const int Total = (int)::ChartGetInteger(Chart_ID, CHART_WINDOWS_TOTAL);         \
                                                                                     \
    bool Res = (A);                                                                  \
                                                                                     \
    if (Res)                                                                         \
    {                                                                                \
      string StrBegin;                                                               \
      string StrEnd;                                                                 \
      string SubWindows[];                                                           \
                                                                                     \
      Res = SUBWINDOW::GetSubWindows(Chart_ID, StrBegin, SubWindows, StrEnd) && B && \
            SUBWINDOW::SetSubWindows(Chart_ID, StrBegin, SubWindows, StrEnd);        \
    }                                                                                \
                                                                                     \
    return(Res);                                                                     \
  }

  // Удаление подокна чарта
  static bool Delete( const long Chart_ID, const uint Index )
    SUBWINDOW_MACROS(Index < (uint)Total, SUBWINDOW::DeleteElement(SubWindows, Index))

  // Удаление всех подокон чарта
  static bool DeleteAll( const long Chart_ID = 0 )
    SUBWINDOW_MACROS(Total > 1, ::ArrayResize(SubWindows, 1))

  // Создание копии подокна чарта
  static bool Copy( const long Chart_ID, const uint IndexSrc, const uint IndexDst )
    SUBWINDOW_MACROS(IndexSrc < (uint)Total, SUBWINDOW::AddElement(SubWindows, SubWindows[IndexSrc], IndexDst))

  // Обмен местами подокон чарта
  static bool Swap( const long Chart_ID, const uint Index1, const uint Index2 )
    SUBWINDOW_MACROS(Index1 && Index2 && (Index1 != Index2) && (Index1 < (uint)Total) && (Index2 < (uint)Total),
                      SUBWINDOW::Swap(SubWindows[Index1], SubWindows[Index2]))

#undef SUBWINDOW_MACROS
};