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
    
    fname_abs = \
      str_join((/"perfmetrics", "latlon","Mean", annots(imod), var0, \
                 diag_script_info@time_avg, diag_script_info@region/), "_")
                 
    fname_std = \
      str_join((/"perfmetrics", "latlon","STD", annots(imod), var0, \
                 diag_script_info@time_avg, diag_script_info@region/), "_")
                 
    fname_trend = \
      str_join((/"perfmetrics", "latlon","Trend", annots(imod), var0, \
                 diag_script_info@time_avg, diag_script_info@region/), "_")
                              
    workpath_abs = config_user_info@work_dir + fname_abs + ".nc"
    workpath_trend = config_user_info@work_dir + fname_trend + ".nc"
    
    plotpath_abs = config_user_info@plot_dir + fname_abs
    plotpath_std = config_user_info@plot_dir + fname_std
    plotpath_trend = config_user_info@plot_dir + fname_trend
    
     
    fname_diff = \
      str_join((/"perfmetrics", "latlon", "Bias",\
                 annots(imod) + "-" + annots(ref_ind), var0, \
                 diag_script_info@time_avg, diag_script_info@region/), "_")
                 
    fname_diff_std = \
      str_join((/"perfmetrics", "latlon", "STD_Diff",\
                 annots(imod) + "-" + annots(ref_ind), var0, \
                 diag_script_info@time_avg, diag_script_info@region/), "_")
                 
    fname_diff_trend = \
      str_join((/"perfmetrics", "latlon","Trend_Diff", \
                 annots(imod) + "-" + annots(ref_ind), var0, \
                 diag_script_info@time_avg, diag_script_info@region/), "_")
                 
                        
    workpath_diff = config_user_info@work_dir + fname_diff + ".nc"
    plotpath_diff = config_user_info@plot_dir + fname_diff
    plotpath_diff_std = config_user_info@plot_dir + fname_diff_std
    plotpath_diff_trend = config_user_info@plot_dir + fname_diff_trend
    
        
    ; Determine start/end year
    start_year = info_items[imod]@start_year
    end_year = info_items[imod]@end_year

     nyr = (end_year - start_year )+1


    ; Read data
    var = read_data(info_items[imod])
    dnames = getVarDimNames(var)



    ; Calculate time average and standard dev. w.r.t. interannual variablity
    
    var_avg = time_operations(var, start_year, end_year, "average", \
                              diag_script_info@time_avg, True)
    var_std = interannual_variability(var, start_year, end_year, \
                                      diag_script_info@time_avg, "None")
    
    var_ann = time_operations(var, start_year, end_year, "average", \
                              "yearly", True)
    
    var_ann!0 = "time"
    

     
  ;@@@@@@@@@     Trend Calculation    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  
      
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
     
       
    ;var_trend = var_trend@_FillValue
    var_trend = where(abs(var_trend).ge.1000.0,0,var_trend) 
            
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
      var_diff_trend = where(abs(var_diff_trend).ge.1000.0,0,var_diff_trend) 
      
      var_diff_trend@units = " "
      var_diff_std@units = " "
      
      var_diff_std = where(abs(var_diff_std).ge.1000.0,0,var_diff_std) 
      var_diff_trend = where(abs(var_diff_trend).ge.1000.0,0,var_diff_trend)
      
    end if




    ; Write output
    if (config_user_info@write_netcdf) then
      var_all@ncdf = workpath_abs
      ncdf_abs = ncdf_write(var_all, workpath_abs)
      ;var_all@ncdf = workpath_trend
      ;ncdf_abs = ncdf_write(var_all, workpath_trend)
      if (l_diff) then
        var_diff@ncdf = workpath_diff
        ncdf_diff = ncdf_write(var_diff, workpath_diff)
      end if
    end if



;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
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


   print(" Ploting absolute plot  Clim")
    ; Absolute plot
    plot_var = var_all(:, :, 0)
    plot_var@projection = diag_script_info@projection
    plot_var@res_cnLinesOn = False
    plot_var@res_cnLevelSelectionMode = "ExplicitLevels"
    plot_var@res_tiMainString = "[ " + annots(imod) + " ]" + " Means (Annual) "
    plot_var@res_cnLevels = diag_script_info@abs_levs
    
    plot_var@res_gsnLeftString = \
      plot_var@long_name 
    
   if (diag_script_info@show_global_avg) then  ; append global average
      gavg = area_operations(plot_var, -90., 90., 0., 360., "average", True)
      plot_var@res_gsnRightString = \
        sprintf("%5.2f", gavg) + " " + format_units(plot_var@units)
    end if
    wks = gsn_open_wks(file_type, plotpath_abs)
    gsn_define_colormap(wks, diag_script_info@latlon_cmap)
    plot = contour_map_ce(wks, plot_var, var0)
    draw(plot)
    frame(wks)
    delete(plot_var@res_cnLevels)
    delete(wks)
    delete(plot)
 

   print(" Ploting absolute plot  STD")

    ; Standard deviation plot
    plot_var = var_all(:, :, 1)
    plot_var@projection = diag_script_info@projection
    plot_var@res_cnLinesOn = False
    plot_var@res_cnLevelSelectionMode = "ExplicitLevels"
    plot_var@res_tiMainString = "[ " + annots(imod) + " ]" + " Standard Deviations (Annual) "
    plot_var@res_cnLevels = diag_script_info@std_levs
    plot_var@res_gsnLeftString = \
      plot_var@long_name 
    if (diag_script_info@show_global_avg) then  ; append global average
      gavg = area_operations(plot_var, -90., 90., 0., 360., "average", True)
      plot_var@res_gsnRightString = \
        sprintf("%5.2f", gavg) + " " + format_units(plot_var@units)
    end if
    wks = gsn_open_wks(file_type, plotpath_std)
    ;gsn_define_colormap(wks, diag_script_info@latlon_cmap)
    gsn_define_colormap(wks,"precip3_16lev")  
    plot = contour_map_ce(wks, plot_var, var0)
    draw(plot)
    frame(wks)
    delete(plot_var@res_cnLevels)
    delete(wks)
    delete(plot)
    
    
   print(" Ploting absolute plot  Trend")
    ; Trend plot

    plot_var = var_all_trend(:, :, 0)
    plot_var@projection = diag_script_info@projection
    plot_var@res_cnLinesOn = False
    plot_var@res_cnLevelSelectionMode = "ExplicitLevels"
    plot_var@res_tiMainString =  "[ " + annots(imod) + " ]" + " Trends (Annual) "
    plot_var@res_cnLevels = diag_script_info@trend_levs
    ;plot_var@res_gsnLeftString = \
    ;  plot_var@long_name + " [" + format_units(plot_var@units) + "]"
    plot_var@res_gsnLeftString = \
      plot_var@long_name      
      
    if (diag_script_info@show_global_avg) then  ; append global average
      gavg = area_operations(plot_var, -90., 90., 0., 360., "average", True)
      plot_var@res_gsnRightString = \
        sprintf("%5.2f", gavg) + " " + format_units(plot_var@units)
    end if
    wks = gsn_open_wks(file_type, plotpath_trend)
    gsn_define_colormap(wks, diag_script_info@latlon_cmap)
    plot = contour_map_ce(wks, plot_var, var0)
    draw(plot)
    frame(wks)
    delete(plot_var@res_cnLevels)
    delete(wks)
    delete(plot)



    ; Call provenance logger
    log_provenance(ncdf_abs, \
                   plotpath_abs + "." + file_type, \
                   "Geographical distribution of variable " + var0, \
                   (/"mean", "rmsd"/), \
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
    plot_var@res_tiMainString = " [  " + annots(imod) + " - " + annots(ref_ind) + "  ] " + " Bias (Annual) "
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
      plot_var@long_name      
      
    if (diag_script_info@show_global_avg) then  ; append global average
      gavg = area_operations(plot_var, -90., 90., 0., 360., "average", True)
      plot_var@res_gsnRightString = \
        sprintf("%5.2f", gavg) + " " + format_units(plot_var@units)
    end if
    wks = gsn_open_wks(file_type, plotpath_diff)
    gsn_merge_colormaps(wks, "temp_19lev", "gray70")
    plot = contour_map_ce(wks, plot_var, var0)
    delete(plot_var@res_cnLevels)

    ; Apply t-test (assuming different population variances)
    caption = "Difference in geographical distribution of variable " + var0
    if (diag_script_info@t_test) then
      x1 = var_all(:, :, 0)
      x2 = var_ref(:, :, 0)
      s1 = var_all(:, :, 1) ^ 2
      s2 = var_ref(:, :, 1) ^ 2
      n1 = info_items[imod]@end_year - info_items[imod]@start_year + 1
      n2 = info_items[ref_ind]@end_year - info_items[ref_ind]@start_year + 1
      prob = ttest(x1, s1, n1, x2, s2, n2, True, False)
      mask_var = 1. - prob
      copy_VarCoords(plot_var, mask_var)
      delete(prob)

      ; Mask non-significant values
      res2 = True
      res2@cnLevelSelectionMode = "ExplicitLevels"
      res2@cnLevels = (/0.0, diag_script_info@conf_level, 1.0/)
      res2@cnInfoLabelOn = False
      res2@cnLinesOn = False
      res2@cnLineLabelsOn = False
      res2@gsnDraw = False
      res2@gsnFrame = False
      plot2 = gsn_csm_contour(wks, mask_var, res2)
      opt = True
      if (diag_script_info@stippling) then
        opt@gsnShadeFillType = "pattern"
        opt@gsnShadeLow = 17
        caption = caption + " (non-significant points are stippled)"
      else
        opt@gsnShadeFillType = "color"
        opt@gsnShadeLow = "gray70"
        caption = caption + " (non-significant points are masked out in gray)"
      end if
      plot2 = gsn_contour_shade(plot2, diag_script_info@conf_level, 999., opt)
      overlay(plot, plot2)
      draw(plot)
      frame(wks)
      delete(wks)
      delete(plot)
      delete(plot2)
      delete(mask_var)
      delete(plot_var)

    end if

    ; Difference plot STD to the reference
    if (.not.l_diff) then
      continue
    end if
    plot_var = var_diff_std
    plot_var@projection = diag_script_info@projection
    plot_var@res_tiMainString = " [( " + annots(imod) + " - " + annots(ref_ind) + " ) / " + annots(ref_ind) + "  ]" + " Standard Deviations (Annual) "
    plot_var@res_cnLevelSelectionMode = "ExplicitLevels"
    plot_var@res_cnLevels = diag_script_info@std_diff_levs
    plot_var@res_cnMissingValFillColor = "gray70"
    plot_var@res_gsnSpreadColorEnd = -2
    ;plot_var@res_gsnLeftString = \
    ;  plot_var@long_name + " [" + format_units(plot_var@units) + "]"
    plot_var@res_gsnLeftString = \
      plot_var@long_name      
      
    if (diag_script_info@show_global_avg) then  ; append global average
      gavg = area_operations(plot_var, -90., 90., 0., 360., "average", True)
      plot_var@res_gsnRightString = \
        sprintf("%5.2f", gavg) + " " + format_units(plot_var@units)
    end if
    wks = gsn_open_wks(file_type, plotpath_diff_std)
    gsn_merge_colormaps(wks, "temp_19lev", "gray70")
    plot = contour_map_ce(wks, plot_var, var0)
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
    plot_var@res_tiMainString = " [( " + annots(imod) + " - " + annots(ref_ind) + " ) / " + annots(ref_ind) + "]" + "  Trends (Annual) "
    ;plot_var@res_tiMainString = annots(imod) + " - " + annots(ref_ind) + " [ Trend] "
    plot_var@res_cnLevelSelectionMode = "ExplicitLevels"
    plot_var@res_cnLevels = diag_script_info@trend_diff_levs
    plot_var@res_cnMissingValFillColor = "gray70"
    plot_var@res_gsnSpreadColorEnd = -2
    ;plot_var@res_gsnLeftString = \
    ;  plot_var@long_name + " [" + format_units(plot_var@units) + "]"
    plot_var@res_gsnLeftString = \
      plot_var@long_name      
      
    if (diag_script_info@show_global_avg) then  ; append global average
      gavg = area_operations(plot_var, -90., 90., 0., 360., "average", True)
      plot_var@res_gsnRightString = \
        sprintf("%5.2f", gavg) + " " + format_units(plot_var@units)
    end if
    
    wks = gsn_open_wks(file_type, plotpath_diff_trend)
     setvalues NhlGetWorkspaceObjectId()
         "wsMaximumSize" :150000000
     end setvalues
  
    var5 = var0 
   ; var5@cnLevelSpacingF   = 5
  
    var5@cnRasterSmoothingOn = True
    
     
    gsn_merge_colormaps(wks, "temp_19lev", "gray70")
    plot = contour_map_ce(wks, plot_var, var5)
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
