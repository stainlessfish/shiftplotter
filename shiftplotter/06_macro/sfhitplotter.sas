/*** HELP START ***//*

/*************************************************************************
* Program:    ShiftPlotter.sas
* Macro:       %ShiftPlotter
*

Purpose:
This SAS macro generates shift plots comparing baseline and post-treatment values by treatment groups.
It supports customizable axis labels, symbols, and colors, automatically builds attribute maps and formats, and outputs high-resolution graphics with flexible size and resolution options.

******************************
Features:
 - Produces shift plots comparing baseline and post-treatment values by treatment group
 - Supports customizable axis labels, treatment symbols, and colors
 - Automatically generates attribute maps and user-defined formats for parameters and treatments
 - Allows flexible control of plot size, resolution (DPI), and output location
 - Option to export generated SAS code for reproducibility and debugging


******************************
Parameters:
  DATA= Input dataset with one record per subject
  BYGRP= Variable for by-group processing (default: PARAMN)
  XVAL= X-axis variable (default: BASE)
  XLABEL= X-axis label (default: "Baseline")
  YVAL= Y-axis variable (default: AVAL)
  YLABEL= Y-axis label (default: "Last Value on Treatment Period")
  TRTLABEL= Label variable for treatment group (default: TRTA)
  TRTVARN= Numeric variable for treatment group (default: TRTAN)
  TRTSYMBOL= Symbols for treatment groups (default: circle X square)
  TRTCOLOR= Colors for treatment groups (default: red blue green)
  PARAMLABEL= Label variable for parameter (default: PARAM)
  PARAMNUM= Numeric variable for parameter (default: PARAMN)
  Width= Plot width in pixels (default: 840)
  Height= Plot height in pixels (default: 480)
  DPI= Resolution in dots per inch (default: 300)
  OutputPath= Specifies the output directory. Leave blank for standard SAS output, or set to "WORK" to use the Base SAS temporary directory.
  Generate_Code= Flag to export generated SAS code (Y/N, default: N)


* Example usage:
******************************
* Example :

%ShiftPlotter(
    DATA=PLOTDS
  , BYGRP=PARAMN TRTAN

  , XVAL=BASE
  , XLABEL=Baseline

  , YVAL=AVAL
  , YLABEL=Last Value on Treatment Period

  , TRTVARN=TRTAN
  , TRTLABEL=TRTA
  , TRTSYMBOL=circle X square
  , TRTCOLOR=red blue green

  , PARAMNUM=PARAMN
  , PARAMLABEL=PARAM 

  , width     = 75mm 
  , height    = 65mm 
  , dpi       = 300  

  , OutputPath=C:\temp
  , Generate_Code = N  
);
* 
* Author:     Hiroki Yamanobe
* Date:       2025-09-02
* Version:    0.1*

*//*** HELP END ***/


%macro ShiftPlotter(
   DATA=PLOTDS         /* Dataset must have one record per subject. */
  ,BYGRP=PARAMN        /* Variable of by group */

  ,XVAL=BASE           /* X axis variable*/
  ,XLABEL=Baseline     /* X axis label*/

  ,YVAL=AVAL                              /* Y axis variable*/
  ,YLABEL=Last Value on Treatment Period  /* Y axis label*/

  ,TRTLABEL=TRTA              /* Label Variable of Treatment Group*/
  ,TRTVARN=TRTAN              /* Numeric Variable of Treatment Group*/
  ,TRTSYMBOL=circle X square  /* Symbol of Treatment Group*/
  ,TRTCOLOR=red blue green    /* Color of Treatment Group*/

  ,PARAMLABEL=PARAM           /* Label Variable of Parameter */
  ,PARAMNUM=PARAMN            /* Numeric Variable of Parameter */

  ,width     = 840  /* width of the plot */
  ,height    = 480  /* height of the plot */
  ,dpi       = 300  /* dpi of the plot */

  ,OutputPath=         /* output Path */
  ,Generate_Code = N   /* Flag for output SAS code */
);

/* @@@@@@@@ Generate_Code start */
  options nomfile;
  %if %upcase(&Generate_Code) =Y %then %do;
    %let codepath = %sysfunc(pathname(WORK));
    %let sysind =&sysindex;
    filename mprint "&codepath.\ShiftPlotter&sysind..txt";
    options mfile mprint;
  %end;
/*@@@@@@@@*/

%** Checker;
%if %sysfunc(countw(&TRTSYMBOL., %str( ))) ne %sysfunc(countw(&TRTCOLOR., %str( ))) %then %put WARNING: Check [TRTSYMBOL] or [TRTCOLOR]. Difference Number parameter.;

** import;
data _import;
  set &DATA.(keep= &BYGRP.  &XVAL.  &YVAL. &TRTLABEL. &TRTVARN. &PARAMLABEL. &PARAMNUM.);
run;

proc sort data=_import;
  by &BYGRP.;
run;

%** SG;
title;
footnote;

%** for attrmap;
data attrmap;
  set _import;

  %** Treatment group;
  length  VALUE ID  MARKERSYMBOL  MARKERCOLOR $200.;
  ID       ="TRT";
  format   ="TRT";

  %do i=1 %to %sysfunc(countw(&TRTSYMBOL., %str( )));
    %let _tempSym = %scan(&TRTSYMBOL, &i., %str( ));
    %let _tempClr = %scan(&TRTCOLOR,  &i., %str( ));
    if &TRTVARN. eq &i. then do;VALUE=cats(&TRTLABEL.);  MARKERSYMBOL="%superq(_tempSym)";    MARKERCOLOR="%superq(_tempClr)";   output;end;
  %end;

  keep VALUE--MARKERCOLOR;
run;
proc sort data=attrmap nodupkey;
  by _all_;
run;

%** format ;
data FMT;
  set PLOTDS;
  length FMTNAME$30. START$200. LABEL$200.;
  FMTNAME="TRT";  START=cats(&TRTVARN.);     LABEL=cats(&TRTLABEL.);output;
  FMTNAME="PRM";  START=cats(&PARAMNUM.);    LABEL=cats(&PARAMLABEL.);output;
  keep FMTNAME START LABEL ;
run;
proc sort data=FMT nodupkey;
  by FMTNAME START LABEL ;
run;
proc format lib=work cntlin=FMT;
run;


%** ods graphics;
ods graphics on / width=&WIDTH. height=&HEIGHT. noborder;



%** _wk: path for image_file  ;
%if "%length(&OutputPath.)" ne "0" %then %do;


  %if "%upcase(&OutputPath.)" eq "WORK" %then %do;
    %let _wk=%sysfunc(getoption(work));
    %put &=_wk ;
    ods listing gpath="&_wk." image_dpi=&dpi.;
    ods graphics on / reset=index(1001) imagename="EXT_FIG";
  %end;
  %else %do;
    ods listing gpath="&OutputPath." image_dpi=&dpi.;
    ods graphics on / reset=index(1001) imagename="EXT_FIG" imagefmt=png;

  %end;
%end;


options nobyline;
%let g_FONTSET=Family='Times new Roman' Size=8pt;
title;
footnote;
title "#BYVAL(&PARAMNUM.)";

proc sgplot data=_import 
            dattrmap=attrmap
            aspect=1;
  by &BYGRP.;

  scatter  x=&XVAL. y=&YVAL. / group=&TRTVARN. name="sc" attrid=TRT jitter ;
  xaxis offsetmin=0 label="&XLABEL."   labelattrs=(&g_FONTSET.) valueattrs=(&g_FONTSET.);
  yaxis offsetmin=0 label="&YLABEL."   labelattrs=(&g_FONTSET.) valueattrs=(&g_FONTSET.);

  %** reference  line;
  lineparm x=0 y=0 slope=1 / name="hoge";

  %** legend;
  keylegend "sc"/ 
          title     =''        
          position  =bottom    
          location  =outside   
          sortorder =ascending 
              across    =4         
              down      =1         
          noborder
          valueattrs=(&g_FONTSET. size=7)
          ;

  %** format;
  format &TRTVARN. TRT.;
  format &PARAMNUM. PRM.;
run;

%** resest setting image_file ;
%if %length(&OutputPath.) ne 0 %then %do;
  ods graphics off;
  ods graphics on / reset;
  ods results;
%end;



/*@@@@@@@@ Generate_Code end */
options nomfile;
%if %upcase(&Generate_Code) =Y %then %do;
  %let codepath = %sysfunc(pathname(WORK));
  %let sysind =&sysindex;
  filename mprint "&codepath.\ShiftPlotter&sysind..txt";
  options mfile mprint;
%end;
/*@@@@@@@@*/


%mend ShiftPlotter;
