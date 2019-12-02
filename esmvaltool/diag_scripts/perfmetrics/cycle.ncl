; #############################################################################
; PROCEDURE FOR THE ANNUAL CYCLE PLOT OF THE PERFORMANCE METRICS
; Authors: Mattia Righi (DLR, Germany) and Franziska Frank (DLR, Germany)
; ESMVal project
; #############################################################################

load "$diag_scripts/shared/plot/xy_line.ncl"

procedure perfmetrics_ptype_script()
begin

  ; Define output array
  if (diag_script_info@time_avg.eq."seasonalclim") then
    var_all = new((/nDatasets, 4, 2/), float)
    var_MM = new((/1, 4, 2/), float)
    var_all!1 = "season"
    var_MM!1 = "season"
    var_all&season = (/"DJF", "MAM", "JJA", "SON"/)
  else if (diag_script_info@time_avg.eq."monthlyclim") then
    var_all = new((/nDatasets, 12, 2/), float)
    var_MM = new((/1, 12, 2/), float)
    var_all!1 = "month"
    var_MM!1 = "month"
    var_all&month = (/"J", "F", "M", "A", "M", "J",\
                      "J", "A", "S", "O", "N", "D"/)
    time=(/1,2,3,4,5,6,7,8,9,10,11,12/)               
  else
      error_msg("f", DIAG_SCRIPT, "", "time_avg option " + \
                diag_script_info@time_avg + \
                " not compatible with plot_type cycle")
  end if
  end if
  
; @@@@@@@  Define yearly average array @@@@@@@@
    log_debug("Processing " + datasetnames(0))
    start_year = info_items[0]@start_year
    end_year = info_items[0]@end_year
    
    nyr = (end_year - start_year )+1
    
    print(start_year)
    print(end_year)
   
    
    
    var_all_year = new((/nDatasets, ((end_year - start_year) + 1), 2/), float)
    var_MM_year = new((/1, ((end_year - start_year) + 1), 2/), float)
    var_all_year!1 = "year"
    var_MM_year!1 = "year"
    
    year1 = ispan(start_year,end_year,1)
    
    print("Years")
    print(getvardimnames(year1) + " : " + dimsizes(year1)) 
    
     print("var_all_year")
     
    print(getvardimnames(var_all_year) + " : " + dimsizes(var_all_year)) 
    
     print("var_MM_year")
     
    print(getvardimnames(var_MM_year) + " : " + dimsizes(var_MM_year)) 
    
    years = ispan(start_year,end_year,1)
    
    var_all_year&year = ispan(start_year,end_year,1)
    var_MM_year&year = ispan(start_year,end_year,1)
    
   print(" Hi 1")
    var_all_year!0 = "model"
    var_all_year!2 = "statistic"
    var_all_year&model = datasetnames
    var_all_year&statistic = (/"mean", "stddev"/)
    print(" Hi 2")
    var_MM_year!0 = "model"
    var_MM_year!2 = "statistic"
    var_MM_year&model = "Multi-Model-Mean"
    var_MM_year&statistic = (/"mean", "stddev"/)
   print(" Hi 3")
   ; Attach attributes
    var_all_year@var = var0
    var_all_year@diag_script = (/DIAG_SCRIPT/)
    copy_VarAtts(diag_script_info, var_all_year)
    var_all_year@ref_model = variable_info[0]@reference_dataset
   print(" Hi 4")
    var_MM_year@var = var0
    var_MM_year@diag_script = (/DIAG_SCRIPT/)
    copy_VarAtts(diag_script_info, var_MM_year)
    var_MM_year@ref_model = variable_info[0]@reference_dataset

;@@@@@@@@@@@ END Define yearly average array @@@@@@@@@@@
  
  
  var_all!0 = "model"
  var_all!2 = "statistic"
  var_all&model = datasetnames
  var_all&statistic = (/"mean", "stddev"/)

  print(var_all&model)
   
  var_MM!0 = "model"
  var_MM!2 = "statistic"
  var_MM&model = "Multi-Model-Mean"
  var_MM&statistic = (/"mean", "stddev"/)

print(var_MM&model)

  ; Attach attributes
  var_all@var = var0
  var_all@diag_script = (/DIAG_SCRIPT/)
  copy_VarAtts(diag_script_info, var_all)
  var_all@ref_model = variable_info[0]@reference_dataset

  ; Search for level
  f = addfile(info_items[0]@filename, "r")
  if (isfilevar(f, "plev")) then
    if (dimsizes(f->plev).eq.1) then
      level = toint(f->plev/100.)
    end if
  end if

  ; Set path for saving processed data
  system("mkdir -p " + config_user_info@work_dir)
  if (isdefined("level")) then
    vv = var0 + level
  else
    vv = var0 
  end if
  
  
  fname = str_join((/"perfmetrics", "cycle", vv, \
                     diag_script_info@time_avg, diag_script_info@region/), "_")
  workpath = config_user_info@work_dir + fname + ".nc"
  plotpath = config_user_info@plot_dir + fname
  
  print(workpath)
  print(plotpath)


; @@@@@@@  Loop over datasets   @@@@@@@@

  do imod = 0, nDatasets - 1

    log_debug("Processing " + datasetnames(imod))

    ; Determine start/end year
    start_year = info_items[imod]@start_year
    end_year = info_items[imod]@end_year

    ; Read data
    var1 = read_data(info_items[imod])
    dnames = getVarDimNames(var1)
  
   vard1 = nyr * 12
   vard2 = dimsizes(var1(1,:,1))
   vard3 = dimsizes(var1(1,1,:))
    
   var = new((/vard1,vard2,vard3/),float,var1@_FillValue)
  
  print("vard1")
  print(vard1) 
    print("var(1:vard1-1,:,:)")
  print(getvardimnames(var(1:vard1-1,:,:)) + " : " + dimsizes(var(1:vard1-1,:,:))) 
  
  print("var")
  print(getvardimnames(var) + " : " + dimsizes(var)) 
  print("var1")
  print(getvardimnames(var1) + " : " + dimsizes(var1)) 
        
  if (dimsizes(var1(:,1,1)) .eq. (nyr * 12)) then
    print("hg1")
   var = var1
  else
   print("hg2")
   var(1:dimsizes(var1(:,1,1)),:,:) = var1
  end if
    
   delete(var1)   
    ; print(getvardimnames(var) + " : " + dimsizes(var)) 
      
print(var@units)
print(dimsizes(var(:,1,1)))
print((nyr * 12))
;
 

print(var@units)

 ; Change unit of Temperature
     ; K to C 
     ; -273.15
 ; if (var@units .eq. "K") then
 ;    var = var -273.15
 ;    var@units = "C"	
 ; end if
     
; Change unit of Precipitation 
     ; kg m-2 s-1   to mm/day 
     ; pr1 *= (60*60*24) 
 ; if (var@units .eq. "kg m-2 s-1") then
 ;    var = var * (60 * 60 * 24)
 ;    var@units = "mm/day"
 ;    var@long_name = "precipitation" ;
 ;    var@standard_name = "precipitation" ;	
 ; end if


    ; Calculate yearly anomaly
     var_ano := rmMonAnnCycTLL(var) 

    ; Extract region and average over latitude and longitude
    if (any(dnames.eq."lat") .and. any(dnames.eq."lon")) then
      var_reg = area_operations(var, region(0), region(1), \
                                region(2), region(3), "average", True)
                                
      var_ano_reg = area_operations(var_ano, region(0), region(1), \
                                region(2), region(3), "average", True)                           
    else
      var_reg = var
      var_ano_reg = var_ano
      
    end if
    delete(var)
    delete(var_ano)
    

    
    print("var_reg")
    print(getvardimnames(var_reg) + " : " + dimsizes(var_reg)) 
    print("var_ano_reg")
    print(getvardimnames(var_ano_reg) + " : " + dimsizes(var_ano_reg)) 
     
 
    ; Calculate time average

    var_avg = time_operations(var_reg, start_year, end_year, "average", \
                              diag_script_info@time_avg, True)
                          
    var_ano_avg = time_operations(var_ano_reg, start_year, end_year, "average", \
                          "yearly", True)
      
        
                                                  
    ; Calculate time standard deviation (with lower/upper bounds)
    if (start_year.lt.end_year) then
      var_std = time_operations(var_reg, start_year, end_year, "stddev", \
                                diag_script_info@time_avg, True)
      var_ano_std = 0.                           
    else
      var_std = 0.
      var_ano_std = 0.
    end if
    delete(var_reg)
    delete(var_ano_reg)
      
    ; Store in global array
    var_all(imod, :, 0) = var_avg
    var_all(imod, :, 1) = var_std
   
    var_all_year(imod, :, 0) = var_ano_avg
    var_all_year(imod, :, 1) = var_ano_std
  
    print("var_avg")
    print(getvardimnames(var_avg) + " : " + dimsizes(var_avg)) 
    print("var_std")
    print(getvardimnames(var_std) + " : " + dimsizes(var_std))
 
    print("var_ano_avg")
    print(getvardimnames(var_ano_avg) + " : " + dimsizes(var_ano_avg)) 
    print("var_ano_std")
    print(getvardimnames(var_ano_std) + " : " + dimsizes(var_ano_std))
       
    delete(var_avg)
    delete(var_std)
    delete(var_ano_avg)
    delete(var_ano_std)
  end do

 


print("var_all_year")
print(getvardimnames(var_all_year) + " : " + dimsizes(var_all_year)) 


  ; Write output
  if (config_user_info@write_netcdf) then
    var_all@ncdf = workpath
    ncdf_outfile = ncdf_write(var_all, workpath)
  end if

  ; Plotting
  if (.not.config_user_info@write_plots) then
    return
  end if

  ; Convert units for plotting (if required)
  if (isatt(diag_script_info, "plot_units")) then
    var_all = convert_units(var_all, diag_script_info@plot_units)
  end if



numModels = dimsizes(var_all(:,0,0))

 sum1 = dim_avg_n(var_all(1:numModels-1,:,:),0)
 var_MM = sum1
delete (sum1) 

 var_allMM = array_append_record(var_all,var_MM,0)
delete(var_MM)
 
 
 
 sum1 = dim_avg_n(var_all_year(1:numModels-1,:,:),0)
 var_MM_year = sum1
delete (sum1) 

 var_allMM_year = array_append_record(var_all_year,var_MM_year,0)
delete(var_MM_year)


print(getvardimnames(var_allMM_year) + " : " + dimsizes(var_allMM_year)) 




;@@@@@@@@@ Global average  Trend Calculation    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  
    tarr = transpose(var_allMM_year(:,:,0))

    tttt = dtrend_msg_n(ispan(0,dimsizes(tarr&year)-1,1),tarr,False,True,0)   

    var_trend = (/ onedtond(tttt@slope, (/dimsizes(var_allMM_year&model)/) ) /)

    delete([/tarr,tttt/])        

    var_trend = var_trend * nyr
    var_trend@units = var_allMM_year@units+" "+ nyr +"yr~S~-1~N~"   
    
    print(nyr)
    print(getvardimnames(var_trend) + " : " + dimsizes(var_trend)) 
    print(var_trend@units)      
    print(var_trend)  
    

 print(numModels)
 print("numModels")

print(getvardimnames(var_allMM) + " : " + dimsizes(var_allMM)) 

print(var_all@units)


; -------------------------------------------------------------------------------------------------------------------------------------------------------
 
; @@@@@@@@@@@@@@  BEGIN: Defining plot titles/ file name/ output image directory name / output netCDF directory name   @@@@@@@@@@@@@@ 

do nimod = 0, numModels - 2
 
   ; Annotation and image titles
  title1 = var_all@long_name + " / Yearly Anomalies"
  title2 = var_all@long_name + " / Monthly Cycle"

  Leb =  "Total " + diag_script_info@region + " Anomalies"

  ; These titles and annotations change if a pressure level is given
  caption = var0
  if (isdefined("level")) then
    title1 = title1 + " " + level + " hPa"
    title2 = title2 + " " + level + " hPa"
    caption = caption + level
    delete(level)    
  end if

  ; Output file name for png and nc files depending on the project (CORDEX, CMIP5, ...)
    data_category = info_items[nimod]@project

    if (data_category.eq.("CORDEX")) then
      rcm = info_items[nimod]@dataset
      gcm = info_items[nimod]@driver
      scenario = info_items[nimod]@exp
      ensemble = info_items[nimod]@ensemble
      fname = \
        str_join((/"Cycle",\
                   rcm, gcm, scenario, ensemble + "-" + info_items[ref_ind]@dataset, vv/), "_")
      fnameY = \
        str_join((/"Annual_Anomalies", \
                   rcm, gcm, scenario, ensemble + "-" + info_items[ref_ind]@dataset, vv/), "_")

      output_path = \
        str_join((/data_category, rcm, gcm, scenario,\
                   ensemble, var0/), "/")

    else if (data_category.eq.("CMIP5")) then
      gcm = info_items[nimod]@dataset
      scenario = info_items[nimod]@exp
      ensemble = info_items[nimod]@ensemble
      fname = \
        str_join((/"Cycle",\
                   gcm, scenario, ensemble + "-" + info_items[ref_ind]@dataset, vv/), "_")
      fnameY = \
        str_join((/"Annual_Anomalies", \
                   gcm, scenario, ensemble + "-" + info_items[ref_ind]@dataset, vv/), "_")

      output_path = \
        str_join((/data_category, gcm, scenario,\
                   ensemble, var0/), "/")


    else if (data_category.eq.("ERA5")) then
      gcm = info_items[nimod]@dataset
      fname = \
        str_join((/"Cycle",\
                   gcm + "-" + info_items[ref_ind]@dataset, vv/), "_")
      fnameY = \
        str_join((/"Annual_Anomalies", \
                   gcm + "-" + info_items[ref_ind]@dataset, vv/), "_")

      output_path = \
        str_join((/data_category, gcm,\
                   var0/), "/")
    end if
    end if
    end if

  
  ; Once the file name is defined, we can definal the directory name for png and nc files
  final_output_path_ncfiles = config_user_info@work_dir + output_path + "/"
  final_output_path = config_user_info@plot_dir + output_path + "/"


  ; Set path for saving plots and netcdf files. If it is not created, it creates one.
  system("mkdir -p " + final_output_path)
  system("mkdir -p " + final_output_path_ncfiles)

  workpath = final_output_path_ncfiles + fname + ".nc"
  plotpath = final_output_path + fname
  
  workpathY = final_output_path_ncfiles + fnameY + ".nc"
  plotpathY = final_output_path + fnameY 

; @@@@@@@@@@@@@@  END: Defining plot titles/ file name/ output image directory name / output netCDF directory name   @@@@@@@@@@@@@@ 

; -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 ; @@@@@@@@@@@ PLOT MONTHLY CYCLE @@@@@@@@@@@@@@@@@@@@@@

 ; @@@@@@@@@@@ BEGIN: Set plot resources @@@@@@@@@@@@@@@@@@@@@@
 
   res = True
   res@tmXBPrecision = 2		; set the precision to 2 significant digits

   if (info_items[nimod]@short_name.eq.("pr")) then
	   res@tmYLFormat = "#+^se"	; don't use "e" symbol, always show +/-
	   res@tiYAxisSide = "Right"		; put the Y-axis title on the right
	   res@trXMinF  = min(time) - 0.05 * (max(time) - min(time))
	   res@trXMaxF  = max(time) + 0.05 * (max(time) - min(time))
	   res@trYMinF  = min(var_allMM(:,:,0)) - 0.2 * (max(var_allMM(:,:,0)) - min(var_allMM(:,:,0)))
	   res@trYMaxF  = max(var_allMM(:,:,0)) + 0.2 * (max(var_allMM(:,:,0)) - min(var_allMM(:,:,0)))
   else if (info_items[nimod]@short_name.eq.("tas")) then
           res@tmYLFormat = "0@*+^sg"	; don't use "e" symbol, always show +/-
	   res@tiYAxisSide = "Right"		; put the Y-axis title on the right
	   res@trXMinF  = min(time) - 0.05 * (max(time) - min(time))
	   res@trXMaxF  = max(time) + 0.05 * (max(time) - min(time))
	   res@trYMinF  = min(var_allMM(:,:,0)) - 0.05 * (max(var_allMM(:,:,0)) - min(var_allMM(:,:,0)))
	   res@trYMaxF  = max(var_allMM(:,:,0)) + 0.05 * (max(var_allMM(:,:,0)) - min(var_allMM(:,:,0)))
   end if
   end if


   res@tiMainFontHeightF    = 0.025
   res@gsnMaximize = True ; maximize plot in frame
   res@tmXBMode      = "Explicit"
   res@tmXTOn        = False
   res@tmXBValues    = time
   res@tmXBLabels    = var_all&month

   
   DashPat      =  new(numModels+1,"integer",0) 
   ;DashPat(numModels) = 4  ; Multi model Mean 
   res@xyDashPatterns       =  DashPat


   colorsname = new(numModels+1,string,"gray80")
   colorsname(numModels - 1) = "blue" ; ERA5 
   colorsname(numModels) = "Black"  ; Multi model Mean 
   colorsname(nimod) = "orange" ; For individual models 
   res@xyLineColors         =  colorsname


   LineTh =  new(numModels+1,"integer",3) 
   LineTh(numModels - 1) = 8 ; ERA5
   LineTh(numModels)     = 5 ; Multi model Mean 
   LineTh(nimod)         = 8 ; For individual models 
   res@xyLineThicknesses    =  LineTh

   res@tiYAxisString        =  format_units(var_all@units)
   
   res@tiMainString         = title2
 
 ; @@@@@@@@@@@ END: Set plot resources@@@@@@@@@@@@@@@@@@@@@@
 

 ; @@@@@@@@@@@ BEGIN: Creation of the work space and setting the legend labels and positions (Distinguish between CORDEX and CMIP5)@@@@@@@@@@@@@@@@@@@@@@

  wks_type = "png"
  wks_type@wkWidth = 1024 
  wks_type@wkHeight = 1024 
  ;wks = gsn_open_wks(file_type, plotpath)
  wks = gsn_open_wks(wks_type, plotpath)

  gres = True
  
  if (diag_script_info@region .eq. "sh") then
     gres@YPosPercent = 60. ; expressed as %, 0->100, sets position of top border of legend
  else
     gres@YPosPercent = 85.  ; expressed as %, 0->100, sets position of top border of legend
  end if

                          ;  when gres@Position is set to its default setting of "Top" (Default = 95.)
  gres@XPosPercent = 15.    ; expressed as %, 0->100, sets position of left border of legend(Default = 5.)

  lineres = True
  lineres@lgLineColors = (/"gray80","black","blue","orange"/) ; line colors
  ;lineres@lgDashPatterns = (/0,5,0,0/) ; line colors
    
  lineres@lgLineThicknesses = 5                          ; line thicknesses
  lineres@LineLengthPercent = 3.                        ; expressed as %, 0->100, length of line

  textres = True
  textres@lgLabels = (/info_items[nimod]@project,"Multi-model mean",\
                      var_allMM&model(numModels - 1), info_items[nimod]@dataset/)  ; legend labels (required)

  simple_legend_ndc(wks,gres,lineres,textres)

 ; @@@@@@@@@@@ END: Creation of the work space and setting the legend labels and positions (Distinguish between CORDEX and CMIP5)@@@@@@@@@@@@@@@@@@@@@@
  
  plot = gsn_csm_xy(wks,time,var_allMM(:,:,0),res)


  
  ;draw(plot)
  ;frame(wks)

  delete(wks)
  delete(plot)
  
; -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  
 ; @@@@@@@@@@@ PLOT YEARLY ANOMALIES @@@@@@@@@@@@@@@@@@@@@@

 ; @@@@@@@@@@@ BEGIN: Set plot resources@@@@@@@@@@@@@@@@@@@@@@

  ; We start by deleting the old plot resources that we are going to change 
  delete(res@trXMinF)
  delete(res@trXMaxF)
  delete(res@trYMinF)
  delete(res@trYMaxF)
  delete(res@tmXBValues)
  delete(res@tmXBLabels)
  delete(res@tiMainString)

  ; We copy the resources that we are going to use in the Monthly cycle plot
  res1 = res
  res1@tiMainString = title1
  res1@tmXBPrecision = 2		; set the precision to 2 significant digits
   if (info_items[nimod]@short_name.eq.("pr")) then
	   res1@tmYLFormat = "#+^se"	; don't use "e" symbol, always show +/-
	   res1@tiYAxisSide = "Right"		; put the Y-axis title on the right
	   res1@trXMinF  = min(years) - 1
	   res1@trXMaxF  = max(years) + 1
	   res1@trYMinF  = min(var_allMM_year(:,:,0)) - 0.15 * (max(var_allMM_year(:,:,0)) - min(var_allMM_year(:,:,0)))
	   res1@trYMaxF  = max(var_allMM_year(:,:,0)) + 0.15 * (max(var_allMM_year(:,:,0)) - min(var_allMM_year(:,:,0)))
   else if (info_items[nimod]@short_name.eq.("tas")) then
           res1@tmYLFormat = "0@*+^sg"	; don't use "e" symbol, always show +/-
	   res1@tiYAxisSide = "Right"		; put the Y-axis title on the right
	   res1@trXMinF  = min(years) - 1
	   res1@trXMaxF  = max(years) + 1
	   res1@trYMinF  = min(var_allMM_year(:,:,0)) - 0.05 * (max(var_allMM_year(:,:,0)) - min(var_allMM_year(:,:,0)))
	   res1@trYMaxF  = max(var_allMM_year(:,:,0)) + 0.05 * (max(var_allMM_year(:,:,0)) - min(var_allMM_year(:,:,0)))
   end if
   end if

  res1@tmXBValues    = years
  res1@tmXBLabels    = var_all_year&year
  res1@tmXBLabelStride   = 5 
  res1@gsnMaximize = True ; maxmize plot in frame


 ; @@@@@@@@@@@ BEGIN: Creation of the work space and setting the legend labels and positions (Distinguish between CORDEX and CMIP5)@@@@@@@@@@@@@@@@@@@@@@
  
  ; A work space of 1024x1024 pixels is created as a png file
  wks_type = "png"
  wks_type@wkWidth = 1024 
  wks_type@wkHeight = 1024 
  wks = gsn_open_wks(wks_type, plotpathY)


  ; The gres object represents the legend lines
  if (info_items[nimod]@short_name.eq.("pr")) then
	  gres = True
	  gres@YPosPercent = 85.    ; expressed as %, 0->100, sets position of top border of legend
		                    ;  when gres@Position is set to its default setting of "Top" (Default = 95.)
	  gres@XPosPercent = 32.    ; expressed as %, 0->100, sets position of left border of legend(Default = 5.)
  else if (info_items[nimod]@short_name.eq.("tas")) then
	  gres = True
	  gres@YPosPercent = 85.    ; expressed as %, 0->100, sets position of top border of legend
		                    ;  when gres@Position is set to its default setting of "Top" (Default = 95.)
	  gres@XPosPercent = 25.    ; expressed as %, 0->100, sets position of left border of legend(Default = 5.)
  end if
  end if


  lineres = True
  lineres@lgLineColors = (/"gray80","black","blue","orange"/) ; line colors
  ;lineres@lgDashPatterns = (/0,5,0,0/) ; line colors
    
  lineres@lgLineThicknesses = 5                          ; line thicknesses
  lineres@LineLengthPercent = 3.                        ; expressed as %, 0->100, length of line


  ; The textres object represents the legend names
  textres = True
  textres@lgLabels = (/info_items[nimod]@project,"Multi-model mean",\
		      var_allMM&model(numModels - 1),info_items[nimod]@dataset/)  ; legend labels (required)

  simple_legend_ndc(wks,gres,lineres,textres)

 ; @@@@@@@@@@@ END: Creation of the work space and setting the legend labels and positions @@@@@@@@@@@@@@@@@@@@@@
  


 ; @@@@@@@@@@@ BEGIN: Text for writting the values of the total anomalies for the model studied and the Reference dataset @@@@@@@@@@@@@@@@@@@@@@

  if (info_items[nimod]@short_name.eq.("pr")) then
	  txres               = True                     ; text mods desired
	  txres@txFontHeightF = 0.018                   ; font smaller. default big
	  txres@txFontColor = "black"
	  txres@txJust        = "CenterLeft"              ; Default is "CenterCenter".
	; page coordinates are normalized. go from 0->1 not 0->8" etc.
	  gsn_text_ndc(wks,Leb,0.55,0.85,txres) 

	 txres1 = txres
	 txres1@txFontColor = "blue"
	 leb1 = sprintf("%5.2E", var_trend(numModels - 1)) + " " + format_units(var_trend@units) 
	 gsn_text_ndc(wks,leb1,0.55,0.82,txres1) 
	 
	 txres2 = txres
	 txres2@txFontColor = "orange"
	 leb2 = sprintf("%5.2E", var_trend(nimod)) + " " + format_units(var_trend@units) 
	 gsn_text_ndc(wks,leb2,0.55,0.79,txres2) 

  else if (info_items[nimod]@short_name.eq.("tas")) then
	  txres               = True                     ; text mods desired
	  txres@txFontHeightF = 0.018                     ; font smaller. default big
	  txres@txFontColor = "black"
	  txres@txJust        = "CenterLeft"              ; Default is "CenterCenter".
	; page coordinates are normalized. go from 0->1 not 0->8" etc.
	  gsn_text_ndc(wks,Leb,0.55,0.85,txres) 

	 txres1 = txres
	 txres1@txFontColor = "blue"
	 leb1 = sprintf("%5.2f", var_trend(numModels - 1)) + " " + format_units(var_trend@units) 
	 gsn_text_ndc(wks,leb1,0.55,0.82,txres1) 
	 
	 txres2 = txres
	 txres2@txFontColor = "orange"
	 leb2 = sprintf("%5.2f", var_trend(nimod)) + " " + format_units(var_trend@units) 
	 gsn_text_ndc(wks,leb2,0.55,0.79,txres2) 
  ; Another else if can be added here for future variables
  end if 
  end if

 ; @@@@@@@@@@@ END: Text for writting the values of the total anomalies for the model studied and the Reference dataset @@@@@@@@@@@@@@@@@@@@@@
  
 plot = gsn_csm_xy(wks,years,var_allMM_year(:,:,0),res1)


  
  ;draw(plot)
  ;frame(wks)
  
  delete(wks)
  delete(plot)
; @@@@@@@@@@@@@@@@@@   END Yearly PLOT  @@@@@@@@@@@@@@@@@@@@@@@@
     
end do 




  ; Call provenance logger
  log_provenance(ncdf_outfile, \
                 plotpath + "." + file_type, \
                 "Cycle plot of variable " + caption, \
                 (/"mean", "stddev"/), \
                 diag_script_info@region, \
                 "seas", \
                 (/"fran_fr", "righ_ma", "eyri_ve"/), \
                 (/"righi15gmd", "gleckler08jgr"/), \
                 metadata_att_as_array(info_items, "filename"))

end
