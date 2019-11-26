; #############################################################################
; PROCEDURE FOR THE LATLON PLOT OF THE PERFORMANCE METRICS
; Authors: Mattia Righi (DLR, Germany) and Franziska Frank (DLR, Germany)
; ESMVal project
; #############################################################################

load "$diag_scripts/shared/plot/style.ncl"
load "$diag_scripts/shared/plot/contour_maps.ncl"

procedure perfmetrics_ptype_script()
begin

  ; Set dataset indexes, with reference dataset first
  modidx = ispan(0, nDatasets - 1, 1)
  modidx := array_append_record(ref_ind, modidx(ind(modidx.ne.ref_ind)), 0)

  annots = project_style(info_items, diag_script_info, "annots")

  ; Loop over datasets
  do ii = 0, dimsizes(modidx) - 1

    imod = modidx(ii)

    log_debug("Processing " + datasetnames(imod))

    ; Check if difference is possible
    if (diag_script_info@plot_diff .and. imod.ne.ref_ind) then
      l_diff = True
    else
      l_diff = False
    end if

    ; Set path for saving processed data
    system("mkdir -p " + config_user_info@work_dir)

; --------------------------------------------------------------------------------------------------------------------------------------------------------------------

; @@@@@@@@@@@@@@  BEGIN: Defining plot titles/ file name/ output image directory name / output netCDF directory name   @@@@@@@@@@@@@@

    data_category = info_items[imod]@project
    if (data_category.eq.("CORDEX")) then
      rcm = info_items[imod]@dataset
      gcm = info_items[imod]@driver
      scenario = info_items[imod]@exp
      ensemble = info_items[imod]@ensemble
      fname_abs = \
        str_join((/"Mean",\
                   rcm, gcm, scenario, ensemble, var0/), "_")

      fname_std = \
        str_join((/"STD",\
                   rcm, gcm, scenario, var0/), "_")

      fname_trend = \
        str_join((/"Trend",\
                   rcm, gcm, scenario, ensemble, var0/), "_")

      fname_diff = \
        str_join((/"Bias",\
                   rcm, gcm, scenario, ensemble + "-" + annots(ref_ind), var0/), "_")

      fname_diff_std = \
        str_join((/"STD_Diff",\
                   rcm, gcm, scenario, ensemble + "-" + annots(ref_ind), var0/), "_")

      fname_diff_trend = \
        str_join((/"Trend_Diff",\
                   rcm, gcm, scenario, ensemble + "-" + annots(ref_ind), var0/), "_")

      output_path = \
        str_join((/data_category, rcm, gcm, scenario,\
                   ensemble, var0/), "/")

    else if (data_category.eq.("CMIP5")) then
      gcm = info_items[imod]@dataset
      scenario = info_items[imod]@exp
      ensemble = info_items[imod]@ensemble
      fname_abs = \
        str_join((/"Mean",\
                   gcm, scenario, ensemble, var0/), "_")

      fname_std = \
        str_join((/"STD",\
                   gcm, scenario, ensemble, var0/), "_")

      fname_trend = \
        str_join((/"Trend",\
                   gcm, scenario, ensemble, var0/), "_")

      fname_diff = \
        str_join((/"Bias",\
                   gcm, scenario, ensemble + "-" + annots(ref_ind), var0/), "_")

      fname_diff_std = \
        str_join((/"STD_Diff",\
                   gcm, scenario, ensemble + "-" + annots(ref_ind), var0/), "_")

      fname_diff_trend = \
        str_join((/"Trend_Diff",\
                   gcm, scenario, ensemble + "-" + annots(ref_ind), var0/), "_")

      output_path = \
        str_join((/data_category, gcm, scenario,\
                   ensemble, var0/), "/")


    else
      gcm = info_items[imod]@dataset
      fname_abs = \
        str_join((/"Mean",\
                 gcm, var0/), "_")

      fname_std = \
        str_join((/"STD",\
                 gcm, var0/), "_")

      fname_trend = \
        str_join((/"Trend",\
                 gcm, var0/), "_")

      fname_diff = \
        str_join((/"Bias",\
                   gcm + "-" + annots(ref_ind), var0/), "_")

      fname_diff_std = \
        str_join((/"STD_Diff",\
                   gcm + "-" + annots(ref_ind), var0/), "_")

      fname_diff_trend = \
        str_join((/"Trend_Diff",\
                   gcm + "-" + annots(ref_ind), var0/), "_")

      output_path = \
        str_join((/data_category, gcm,\
                   var0/), "/")
    end if
    end if

    final_output_path_ncfiles = config_user_info@work_dir + output_path + "/"
    ; Set path for saving plots
    system("mkdir -p " + final_output_path_ncfiles)

    workpath_abs = final_output_path_ncfiles  + fname_abs + ".nc"
    workpath_std = final_output_path_ncfiles + fname_std + ".nc"
    workpath_trend = final_output_path_ncfiles + fname_trend + ".nc"

    final_output_path = config_user_info@plot_dir + output_path + "/"
    ; Set path for saving plots
    system("mkdir -p " + final_output_path)

    plotpath_abs = final_output_path + fname_abs
    plotpath_std = final_output_path + fname_std
    plotpath_trend = final_output_path + fname_trend


    workpath_diff = final_output_path_ncfiles + fname_diff + ".nc"
    workpath_diff_std = final_output_path_ncfiles + fname_diff_std + ".nc"
    workpath_diff_trend = final_output_path_ncfiles + fname_diff_trend + ".nc"


    plotpath_diff = final_output_path + fname_diff
    plotpath_diff_std = final_output_path + fname_diff_std
    plotpath_diff_trend = final_output_path + fname_diff_trend

; @@@@@@@@@@@@@@  END: Defining plot titles/ file name/ output image directory name / output netCDF directory name   @@@@@@@@@@@@@@

; --------------------------------------------------------------------------------------------------------------------------------------------------------------------


    ; Determine start/end year
    start_year = info_items[imod]@start_year
    end_year = info_items[imod]@end_year

     nyr = (end_year - start_year )+1


    ; Read data
    var = read_data(info_items[imod])
    dnames = getVarDimNames(var)



   print(getvardimnames(var) + " : " + dimsizes(var))
   print(var@units)

; --------------------------------------------------------------------------------------------------------------------------------------------------------------------

; @@@@@@@@@@@@@@  BEGIN: Change of units (now, it is not neccessary)   @@@@@@@@@@@@@@

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

; @@@@@@@@@@@@@@  END: Change of units (now, it is not neccessary)   @@@@@@@@@@@@@@

; --------------------------------------------------------------------------------------------------------------------------------------------------------------------

; @@@@@@@@@@@@@@  BEGIN: Calculation of mean and standard deviation   @@@@@@@@@@@@@@

    ; Calculate time average and standard dev. w.r.t. interannual variablity

    var_avg = time_operations(var, start_year, end_year, "average", \
                              diag_script_info@time_avg, True)
    var_std = interannual_variability(var, start_year, end_year, \
                                      diag_script_info@time_avg, "None")

    var_ann = time_operations(var, start_year, end_year, "average", \
                              "yearly", True)

    var_ann!0 = "time"

; @@@@@@@@@@@@@@  END: Calculation of mean and standard deviation   @@@@@@@@@@@@@@

; --------------------------------------------------------------------------------------------------------------------------------------------------------------------

;@@@@@@@@@   BEGIN:  Trend Calculation    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    trends_ann  = var(0,:,:)
    tarr = var_ann


    tttt = dtrend_msg_n(ispan(0,dimsizes(tarr&time)-1,1),tarr,False,True,0)

    var_trend = (/ onedtond(tttt@slope, (/dimsizes(tarr&lat),dimsizes(tarr&lon)/) ) /)

    var_trend!0 = "lat"
    var_trend!1 = "lon"

    var_trend&lat = var_avg&lat
    var_trend&lon = var_avg&lon

    delete([/tarr,tttt/])

    var_trend = var_trend * nyr
    var_trend@units = var_ann@units+" "+ nyr +"yr~S~-1~N~"

   ; print(nyr)
   ; print(getvardimnames(trends_ann) + " : " + dimsizes(trends_ann))
   ; print(trends_ann@units)
    delete([/var_ann/])


    var_trend = where(abs(var_trend).ge.1000.0,var_trend@_FillValue,var_trend)

    delete(var)


  ; Store data in for model and reference in same array

    var_all = new(array_append_record(dimsizes(var_avg), 2, 0), float)
    var_all_trend = new(array_append_record(dimsizes(var_avg), 1, 0), float)


    var_all!2 = "statistic"
    var_all&statistic = (/"mean", "stddev"/)
    var_all(:, :, 0) = var_avg
    var_all(:, :, 1) = var_std

    var_all_trend!2 = "statistic"
    var_all_trend&statistic = (/"trend"/)
    var_all_trend(:, :, 0) = var_trend


    var_all@var = var0
    var_all@diag_script = (/DIAG_SCRIPT/)
    copy_VarAtts(diag_script_info, var_all)
    var_all@ref_model = variable_info[0]@reference_dataset


    var_all_trend@var = var0
    var_all_trend@diag_script = (/DIAG_SCRIPT/)
    copy_VarAtts(diag_script_info, var_all_trend)
    var_all_trend@ref_model = variable_info[0]@reference_dataset

    delete(var_avg)
    delete(var_std)
    delete(var_trend)


  ; Store reference dataset
    if (imod.eq.ref_ind) then
      var_ref = var_all
      var_ref_trend = var_all_trend
    end if


    ; Calculate difference
    if (l_diff) then
      var_diff = var_all(:, :, 0)
      var_diff = var_all(:, :, 0) - var_ref(:, :, 0)

      var_diff_std = var_all(:, :, 1)
      var_diff_std = ((var_all(:, :, 1) - var_ref(:, :, 1)) /  var_ref(:, :, 1))
      ;var_diff_std = var_all(:, :, 1) - var_ref(:, :, 1)

      var_ref_trend@_FillValue = 0.0
      var_diff_trend = var_all_trend(:, :, 0)
      var_diff_trend = ((var_all_trend(:, :, 0) - var_ref_trend(:, :, 0)) /  var_ref_trend(:, :, 0))
      ;var_diff_trend = var_all_trend(:, :, 0) - var_ref_trend(:, :, 0)

      var_diff_trend@units = " "
      var_diff_std@units = " "

      var_diff = where(abs(var_diff).ge.1000.0,var_diff@_FillValue,var_diff)
      var_diff_std = where(abs(var_diff_std).ge.1000.0,var_diff_std@_FillValue,var_diff_std)
      var_diff_trend = where(abs(var_diff_trend).ge.1000.0,var_diff_trend@_FillValue,var_diff_trend)

    end if

;@@@@@@@@@   END:  Trend Calculation    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

; --------------------------------------------------------------------------------------------------------------------------------------------------------------------

;@@@@@@@@@   BEGIN:  NetCDF production    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    ; Write output
    if (config_user_info@write_netcdf) then
      var_avg_nc = var_all(:, :, 0)
      var_std_nc = var_all(:, :, 1)
      var_trend_nc = var_all_trend
      var_avg_nc@ncdf = workpath_abs
      var_std_nc@ncdf = workpath_std
      var_trend_nc@ncdf = workpath_trend
      ncdf_avg = ncdf_write(var_avg_nc, workpath_abs)
      ncdf_std = ncdf_write(var_std_nc, workpath_std)
      ncdf_trend = ncdf_write(var_trend_nc, workpath_trend)
      ;var_all@ncdf = workpath_trend
      ;ncdf_abs = ncdf_write(var_all, workpath_trend)
      if (l_diff) then
        var_diff_trend@ncdf = workpath_diff_trend
        var_diff@ncdf = workpath_diff
        var_diff_std@ncdf = workpath_diff_std
        ncdf_diff = ncdf_write(var_diff, workpath_diff)
        ncdf_diff_std = ncdf_write(var_diff_std, workpath_diff_std)
        ncdf_diff_trend = ncdf_write(var_diff_trend, workpath_diff_trend)
      end if
    end if

;@@@@@@@@@   END:  NetCDF production    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



    ; Plotting
    if (.not.config_user_info@write_plots) then
      continue
    end if

    ; Convert units for plotting (if required)
    if (isatt(diag_script_info, "plot_units")) then
      var_all = convert_units(var_all, diag_script_info@plot_units)
      if (l_diff)
        var_diff = convert_units(var_diff, diag_script_info@plot_units)
      end if
    end if

; --------------------------------------------------------------------------------------------------------------------------------------------------------------------

; @@@@@@@@@@@@@@  BEGIN: Plot for the absolute mean over the total period   @@@@@@@@@@@@@@

   print(" Ploting absolute plot  Clim")
    ; Absolute plot
    plot_var = var_all(:, :, 0)

    ; Need to convert all the missing values to NaN, not to 0
    plot_var = where(abs(plot_var).ge.1000.0,plot_var@_FillValue,plot_var)

    plot_var@projection = diag_script_info@projection
    plot_var@res_cnLinesOn = False
    plot_var@res_cnLevelSelectionMode = "ExplicitLevels"

    ; The title of the figure depends on the data category (CORDEX, CMIP5, ERA5, ...)
    if (data_category.eq.("CORDEX")) then
    	plot_var@res_tiMainString = info_items[imod]@dataset + " / " + plot_var@long_name  + " / " +  "Mean"
    else if (data_category.eq.("CMIP5")) then
    	plot_var@res_tiMainString = info_items[imod]@dataset + " / " + plot_var@long_name  + " / " +  "Mean"
    else if (data_category.eq.("ERA5")) then
        plot_var@res_tiMainString = info_items[ref_ind]@dataset + " / " + plot_var@long_name  + " / " +  "Mean"
    ; Here, other else if can be added for other projects
    end if
    end if
    end if

   plot_var@res_cnLevels = diag_script_info@abs_levs
   plot_var@res_gsnLeftString = \
      		"Annual / " + start_year + " - " + end_year

    if (diag_script_info@show_global_avg) then  ; append global average
      gavg = area_operations(plot_var, -90., 90., 0., 360., "average", True)
      if (info_items[imod]@short_name.eq.("pr")) then
	      plot_var@res_gsnRightString = \
		sprintf("%5.3E", gavg) + " " + format_units(plot_var@units)
      else if (info_items[imod]@short_name.eq.("tas")) then
	      plot_var@res_gsnRightString = \
		sprintf("%5.2f", gavg) + " " + format_units(plot_var@units)
      end if
      end if
    end if

    plot_var@res_lbOrientation = "vertical"; vertical label bar
    plot_var@res_gsnMaximize = True ; maximize plot in frame

    if (info_items[imod]@short_name.eq.("pr")) then
    	plot_var@res_lbLabelStrings = sprintf ("%5.3E",plot_var@res_cnLevels)
    else if (info_items[imod]@short_name.eq.("tas")) then
    	plot_var@res_lbLabelStrings = sprintf ("%5.2f",plot_var@res_cnLevels)
    end if
    end if


    wks = gsn_open_wks(file_type, plotpath_abs)
    gsn_define_colormap(wks, diag_script_info@cmap)
    plot = contour_map_ce(wks, plot_var, var0)

    ;************************************************
    ; Draw text on plot using NDC coordinates
    ;************************************************
    txres               = True                     ; text mods desired
    txres@txFontHeightF = 0.015                     ; font smaller. default big
    txres@txJust        = "CenterLeft"              ; Default is "CenterCenter".

    ; The region footnote depends on the value of the region string given in the recipe
    gsn_text_ndc(wks,"Region: " + diag_script_info@region + " (" + tostring(region(0)) + ", " + tostring(region(1)) + ", " + tostring(region(2)) + ", " + tostring(region(3)) + ")" ,0.1,0.25, txres)

    if (info_items[imod]@short_name.eq.("pr")) then
    	gsn_text_ndc(wks, format_units(plot_var@units),0.86,0.29, txres)
    else if (info_items[imod]@short_name.eq.("tas")) then
        gsn_text_ndc(wks, format_units(plot_var@units),0.88,0.29, txres)
    end if
    end if

    draw(plot)
    frame(wks)
    delete(plot_var@res_cnLevels)
    delete(plot_var@res_lbLabelStrings)
    delete(wks)
    delete(plot)

; @@@@@@@@@@@@@@  END: Plot for the absolute mean over the total period   @@@@@@@@@@@@@@

; --------------------------------------------------------------------------------------------------------------------------------------------------------------------

; @@@@@@@@@@@@@@  BEGIN: Plot for the absolute standard deviation over the total period   @@@@@@@@@@@@@@

   print(" Ploting absolute plot  STD")

    ; Standard deviation plot
    plot_var = var_all(:, :, 1)

    ; Need to convert all the missing values to NaN, not to 0
    plot_var = where(abs(plot_var).ge.1000.0,plot_var@_FillValue,plot_var)

    plot_var@projection = diag_script_info@projection
    plot_var@res_cnLinesOn = False
    plot_var@res_cnLevelSelectionMode = "ExplicitLevels"

    ; The title of the figure depends on the data category (CORDEX, CMIP5, ERA5, ...)
    if (data_category.eq.("CORDEX")) then
    	plot_var@res_tiMainString = info_items[imod]@dataset + " / " + plot_var@long_name  + " / " +  "STD"
    else if (data_category.eq.("CMIP5")) then
    	plot_var@res_tiMainString = info_items[imod]@dataset + " / " + plot_var@long_name  + " / " +  "STD"
    else if (data_category.eq.("ERA5")) then
        plot_var@res_tiMainString = info_items[ref_ind]@dataset + " / " + plot_var@long_name  + " / " +  "STD"
    ; Here, other else if can be added for other projects
    end if
    end if
    end if

    plot_var@res_cnLevels = diag_script_info@std_levs
    plot_var@res_gsnLeftString = \
      		"Annual / " + start_year + " - " + end_year


    if (diag_script_info@show_global_avg) then  ; append global average
      gavg = area_operations(plot_var, -90., 90., 0., 360., "average", True)
      if (info_items[imod]@short_name.eq.("pr")) then
	      plot_var@res_gsnRightString = \
		sprintf("%5.3E", gavg) + " " + format_units(plot_var@units)
      else if (info_items[imod]@short_name.eq.("tas")) then
	      plot_var@res_gsnRightString = \
		sprintf("%5.2f", gavg) + " " + format_units(plot_var@units)
      end if
      end if
    end if

    plot_var@res_lbOrientation = "vertical"; vertical label bar
    plot_var@res_gsnMaximize = True ; maximize plot in frame

    if (info_items[imod]@short_name.eq.("pr")) then
    	plot_var@res_lbLabelStrings = sprintf ("%5.3E",plot_var@res_cnLevels)
    else if (info_items[imod]@short_name.eq.("tas")) then
    	plot_var@res_lbLabelStrings = sprintf ("%5.2f",plot_var@res_cnLevels)
    end if
    end if

    wks = gsn_open_wks(file_type, plotpath_std)
    gsn_define_colormap(wks, diag_script_info@cmap)
    plot = contour_map_ce(wks, plot_var, var0)

    ; The region footnote depends on the value of the region string given in the recipe
    gsn_text_ndc(wks,"Region: " + diag_script_info@region + " (" + tostring(region(0)) + ", " + tostring(region(1)) + ", " + tostring(region(2)) + ", " + tostring(region(3)) + ")" ,0.1,0.25, txres)

    if (info_items[imod]@short_name.eq.("pr")) then
    	gsn_text_ndc(wks, format_units(plot_var@units),0.86,0.29, txres)
    else if (info_items[imod]@short_name.eq.("tas")) then
        gsn_text_ndc(wks, format_units(plot_var@units),0.88,0.29, txres)
    end if
    end if

    draw(plot)
    frame(wks)
    delete(plot_var@res_cnLevels)
    delete(plot_var@res_lbLabelStrings)
    delete(wks)
    delete(plot)


; @@@@@@@@@@@@@@  END: Plot for the absolute standard deviation over the total period   @@@@@@@@@@@@@@

; --------------------------------------------------------------------------------------------------------------------------------------------------------------------

; @@@@@@@@@@@@@@  BEGIN: Plot for the absolute trend over the total period   @@@@@@@@@@@@@@

   print(" Ploting absolute plot  Trend")
    ; Trend plot

    plot_var = var_all_trend(:, :, 0)
    plot_var = where(abs(plot_var).ge.1000.0,plot_var@_FillValue,plot_var)
    plot_var@projection = diag_script_info@projection
    plot_var@res_cnLinesOn = False
    plot_var@res_cnLevelSelectionMode = "ExplicitLevels"

    ; The title of the figure depends on the data category (CORDEX, CMIP5, ERA5, ...)
    if (data_category.eq.("CORDEX")) then
    	plot_var@res_tiMainString = info_items[imod]@dataset + " / " + plot_var@long_name  + " / " +  "Mean"
    else if (data_category.eq.("CMIP5")) then
    	plot_var@res_tiMainString = info_items[imod]@dataset + " / " + plot_var@long_name  + " / " +  "Mean"
    else if (data_category.eq.("ERA5")) then
        plot_var@res_tiMainString = info_items[ref_ind]@dataset + " / " + plot_var@long_name  + " / " +  "Mean"
    ; Here, other else if can be added for other projects
    end if
    end if
    end if

    plot_var@res_cnLevels = diag_script_info@trend_levs
    plot_var@res_gsnLeftString = \
      		"Annual / " + start_year + " - " + end_year

    if (diag_script_info@show_global_avg) then  ; append global average
      gavg = area_operations(plot_var, -90., 90., 0., 360., "average", True)
      if (info_items[imod]@short_name.eq.("pr")) then
	      plot_var@res_gsnRightString = \
		sprintf("%5.3E", gavg) + " " + format_units(plot_var@units)
      else if (info_items[imod]@short_name.eq.("tas")) then
	      plot_var@res_gsnRightString = \
		sprintf("%5.2f", gavg) + " " + format_units(plot_var@units)
      end if
      end if
    end if

    plot_var@res_lbOrientation = "vertical"; vertical label bar
    plot_var@res_gsnMaximize = True ; maximize plot in frame

    if (info_items[imod]@short_name.eq.("pr")) then
    	plot_var@res_lbLabelStrings = sprintf ("%5.3E",plot_var@res_cnLevels)
    else if (info_items[imod]@short_name.eq.("tas")) then
    	plot_var@res_lbLabelStrings = sprintf ("%5.2f",plot_var@res_cnLevels)
    end if
    end if

    wks = gsn_open_wks(file_type, plotpath_trend)
    gsn_define_colormap(wks, diag_script_info@cmap)
    plot = contour_map_ce(wks, plot_var, var0)

    ; The region footnote depends on the value of the region string given in the recipe
    gsn_text_ndc(wks,"Region: " + diag_script_info@region + " (" + tostring(region(0)) + ", " + tostring(region(1)) + ", " + tostring(region(2)) + ", " + tostring(region(3)) + ")" ,0.1,0.25, txres)

    if (info_items[imod]@short_name.eq.("pr")) then
    	gsn_text_ndc(wks, format_units(plot_var@units),0.84,0.29, txres)
    else if (info_items[imod]@short_name.eq.("tas")) then
        gsn_text_ndc(wks, format_units(plot_var@units),0.88,0.29, txres)
    end if
    end if


    draw(plot)
    frame(wks)
    delete(plot_var@res_cnLevels)
    delete(plot_var@res_lbLabelStrings)
    delete(wks)
    delete(plot)

; @@@@@@@@@@@@@@  END: Plot for the absolute trend over the total period   @@@@@@@@@@@@@@

    ; Call provenance logger
    log_provenance(ncdf_avg, \
                   plotpath_abs + "." + file_type, \
                   "Geographical distribution of variable " + var0, \
                   (/"mean"/), \
                   diag_script_info@region, \
                   "geo", \
                   (/"fran_fr", "righ_ma", "eyri_ve"/), \
                   (/"righi15gmd", "gleckler08jgr"/), \
                   info_items[imod]@filename)


;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    ; Difference plot to the reference
    if (.not.l_diff) then
      continue
    end if
    plot_var = var_diff
    plot_var@projection = diag_script_info@projection
    plot_var@res_tiMainString = info_items[imod]@dataset + " / " + plot_var@long_name + " / " +  "Bias"

    if (isatt(diag_script_info, "t_test")) then
      plot_var@res_gsnLeftString = plot_var@res_gsnLeftString + " - " + \
        sprinti("%2i", toint(100 * diag_script_info@conf_level)) + "% c.l."
    end if
    plot_var@res_cnLevelSelectionMode = "ExplicitLevels"
    plot_var@res_cnLevels = diag_script_info@diff_levs
    plot_var@res_cnMissingValFillColor = "gray70"
    plot_var@res_gsnSpreadColorEnd = -2
    ;plot_var@res_gsnLeftString = \
    ;  plot_var@long_name + " [" + format_units(plot_var@units) + "]"
    plot_var@res_gsnLeftString = \
      		"Annual / " + start_year + " - " + end_year


    if (diag_script_info@show_global_avg) then  ; append global average
      gavg = area_operations(plot_var, -90., 90., 0., 360., "average", True)
      if (info_items[imod]@short_name.eq.("pr")) then
	      plot_var@res_gsnRightString = \
		sprintf("%5.3E", gavg) + " " + format_units(plot_var@units)
      else if (info_items[imod]@short_name.eq.("tas")) then
	      plot_var@res_gsnRightString = \
		sprintf("%5.2f", gavg) + " " + format_units(plot_var@units)
      end if
      end if
    end if

    wks = gsn_open_wks(file_type, plotpath_diff)
   ;  setvalues NhlGetWorkspaceObjectId()
   ;      "wsMaximumSize" :300000000
   ;  end setvalues

    if (info_items[imod]@short_name.eq.("pr")) then
    	plot_var@res_lbLabelStrings = sprintf ("%5.3E",plot_var@res_cnLevels)
    else if (info_items[imod]@short_name.eq.("tas")) then
    	plot_var@res_lbLabelStrings = sprintf ("%5.2f",plot_var@res_cnLevels)
    end if
    end if

    gsn_define_colormap(wks, diag_script_info@diff_cmap)
    plot = contour_map_ce(wks, plot_var, var0)

    ;************************************************
    ; Draw text on plot using NDC coordinates
    ;************************************************
    txres               = True                     ; text mods desired
    txres@txFontHeightF = 0.015                     ; font smaller. default big
    txres@txJust        = "CenterLeft"              ; Default is "CenterCenter".


    ; The region footnote depends on the value of the region string given in the recipe
    gsn_text_ndc(wks,"Region: " + diag_script_info@region + " (" + tostring(region(0)) + ", " + tostring(region(1)) + ", " + tostring(region(2)) + ", " + tostring(region(3)) + ")" ,0.1,0.25, txres)
    gsn_text_ndc(wks,"Reference dataset: " + info_items[ref_ind]@dataset,0.1,0.2,txres)

    if (info_items[imod]@short_name.eq.("pr")) then
    	gsn_text_ndc(wks, format_units(plot_var@units),0.86,0.29, txres)
    else if (info_items[imod]@short_name.eq.("tas")) then
        gsn_text_ndc(wks, format_units(plot_var@units),0.88,0.29, txres)
    end if
    end if

    delete(plot_var@res_cnLevels)
    delete(plot_var@res_lbLabelStrings)
    draw(plot)
    frame(wks)
    delete(wks)
    delete(plot)



 ;   ; Apply t-test (assuming different population variances)
     caption = "Difference in geographical distribution of variable " + var0
 ;   if (diag_script_info@t_test) then
 ;     x1 = var_all(:, :, 0)
 ;     x2 = var_ref(:, :, 0)
 ;     s1 = var_all(:, :, 1) ^ 2
 ;     s2 = var_ref(:, :, 1) ^ 2
 ;     n1 = info_items[imod]@end_year - info_items[imod]@start_year + 1
 ;     n2 = info_items[ref_ind]@end_year - info_items[ref_ind]@start_year + 1
 ;     prob = ttest(x1, s1, n1, x2, s2, n2, True, False)
 ;     mask_var = 1. - prob
 ;     copy_VarCoords(plot_var, mask_var)
 ;     delete(prob)

      ; Mask non-significant values
 ;     res2 = True
 ;     res2@cnLevelSelectionMode = "ExplicitLevels"
 ;     res2@cnLevels = (/0.0, diag_script_info@conf_level, 1.0/)
 ;     res2@cnInfoLabelOn = False
 ;     res2@cnLinesOn = False
 ;     res2@cnLineLabelsOn = False
 ;     res2@gsnDraw = False
 ;     res2@gsnFrame = False
 ;     plot2 = gsn_csm_contour(wks, mask_var, res2)
 ;     opt = True
 ;     if (diag_script_info@stippling) then
 ;       opt@gsnShadeFillType = "pattern"
 ;       opt@gsnShadeLow = 17
 ;       caption = caption + " (non-significant points are stippled)"
 ;     else
 ;       opt@gsnShadeFillType = "color"
 ;       opt@gsnShadeLow = "gray70"
 ;       caption = caption + " (non-significant points are masked out in gray)"
 ;     end if
 ;     plot2 = gsn_contour_shade(plot2, diag_script_info@conf_level, 999., opt)
 ;     overlay(plot, plot2)
 ;     draw(plot)
 ;     frame(wks)
 ;     delete(wks)
 ;     delete(plot)
 ;     delete(plot2)
 ;     delete(mask_var)
 ;     delete(plot_var)

 ;  end if

    ; Difference plot STD to the reference
    if (.not.l_diff) then
      continue
    end if
    plot_var = var_diff_std
    plot_var@projection = diag_script_info@projection
    plot_var@res_tiMainString = info_items[imod]@dataset + " / " + plot_var@long_name + " / " +  "STD normalize diff"


    plot_var@res_cnLevelSelectionMode = "ExplicitLevels"
    plot_var@res_cnLevels = diag_script_info@std_diff_levs
    plot_var@res_cnMissingValFillColor = "gray70"
    plot_var@res_gsnSpreadColorEnd = -2
    ;plot_var@res_gsnLeftString = \
    ;  plot_var@long_name + " [" + format_units(plot_var@units) + "]"
    plot_var@res_gsnLeftString = \
      		"Annual / " + start_year + " - " + end_year

    if (diag_script_info@show_global_avg) then  ; append global average
      gavg = area_operations(plot_var, -90., 90., 0., 360., "average", True)
      plot_var@res_gsnRightString = \ diag_script_info@region + " Average: " +
        sprintf("%5.2f", gavg) + " " + format_units(plot_var@units)
    end if
    wks = gsn_open_wks(file_type, plotpath_diff_std)
;     setvalues NhlGetWorkspaceObjectId()
;         "wsMaximumSize" :150000000
;     end setvalues
    gsn_define_colormap(wks, diag_script_info@diff_cmap)
    plot = contour_map_ce(wks, plot_var, var0)

    ;************************************************
    ; Draw text on plot using NDC coordinates
    ;************************************************
    txres               = True                     ; text mods desired
    txres@txFontHeightF = 0.015                     ; font smaller. default big
    txres@txJust        = "CenterLeft"              ; Default is "CenterCenter".

    ; The region footnote depends on the value of the region string given in the recipe
    gsn_text_ndc(wks,"Region: " + diag_script_info@region + " (" + tostring(region(0)) + ", " + tostring(region(1)) + ", " + tostring(region(2)) + ", " + tostring(region(3)) + ")" ,0.1,0.25, txres)
    gsn_text_ndc(wks,"Reference dataset: " + info_items[ref_ind]@dataset,0.1,0.2,txres)

    if (plot_var@units.eq.("kg m-2 s-1")) then
    	gsn_text_ndc(wks, format_units(plot_var@units),0.86,0.29, txres)
    else if (plot_var@units.eq.("K")) then
        gsn_text_ndc(wks, format_units(plot_var@units),0.88,0.29, txres)
    end if
    end if

    delete(plot_var@res_cnLevels)
    draw(plot)
    frame(wks)
    delete(wks)
    delete(plot)


    ; Difference plot Trend to the reference
    if (.not.l_diff) then
      continue
    end if
    plot_var = var_diff_trend
    plot_var@projection = diag_script_info@projection
    plot_var@res_tiMainString = info_items[imod]@dataset + " / " + plot_var@long_name + " / " +  "Trend normalize diff"

    ;plot_var@res_tiMainString = annots(imod) + " - " + annots(ref_ind) + " [ Trend] "
    plot_var@res_cnLevelSelectionMode = "ExplicitLevels"
    plot_var@res_cnLevels = diag_script_info@trend_diff_levs
    plot_var@res_cnMissingValFillColor = "gray70"
    plot_var@res_gsnSpreadColorEnd = -2
    ;plot_var@res_gsnLeftString = \
    ;  plot_var@long_name + " [" + format_units(plot_var@units) + "]"
    plot_var@res_gsnLeftString = \
      		"Annual / " + start_year + " - " + end_year


    if (diag_script_info@show_global_avg) then  ; append global average
      gavg = area_operations(plot_var, -90., 90., 0., 360., "average", True)
      plot_var@res_gsnRightString = \
        sprintf("%5.2f", gavg) + " " + format_units(plot_var@units)
    end if

    wks = gsn_open_wks(file_type, plotpath_diff_trend)
     setvalues NhlGetWorkspaceObjectId()
         "wsMaximumSize" :300000000
     end setvalues

    var5 = var0
   ; var5@cnLevelSpacingF   = 5

    var5@cnRasterSmoothingOn = True


    gsn_define_colormap(wks, diag_script_info@diff_cmap)
    plot = contour_map_ce(wks, plot_var, var5)

    ;************************************************
    ; Draw text on plot using NDC coordinates
    ;************************************************
    txres               = True                     ; text mods desired
    txres@txFontHeightF = 0.015                     ; font smaller. default big
    txres@txJust        = "CenterLeft"              ; Default is "CenterCenter".

    ; The region footnote depends on the value of the region string given in the recipe
    gsn_text_ndc(wks,"Region: " + diag_script_info@region + " (" + tostring(region(0)) + ", " + tostring(region(1)) + ", " + tostring(region(2)) + ", " + tostring(region(3)) + ")" ,0.1,0.25, txres)
    gsn_text_ndc(wks,"Reference dataset: " + info_items[ref_ind]@dataset,0.1,0.2,txres)

    if (plot_var@units.eq.("kg m-2 s-1"+" "+ nyr +"yr~S~-1~N~")) then
    	gsn_text_ndc(wks, format_units(plot_var@units),0.84,0.29, txres)
    else
        gsn_text_ndc(wks, format_units(plot_var@units),0.88,0.29, txres)
    end if

    delete(plot_var@res_cnLevels)
    draw(plot)
    frame(wks)
    delete(wks)
    delete(plot)


    ; Call provenance logger
    log_provenance(ncdf_diff, \
                   plotpath_diff + "." + file_type, \
                   caption, \
                   (/"mean", "rmsd", "diff"/), \
                   diag_script_info@region, \
                   "zonal", \
                   (/"fran_fr", "righ_ma", "eyri_ve"/), \
                   (/"righi15gmd", "gleckler08jgr"/), \
                   info_items[imod]@filename)

  end do

end
