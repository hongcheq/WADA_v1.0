;Function:  difference between TOPOTEST ensemble and CTR ensemble, vertical profile of U.
;Date: 20180709
;Note: modified 20180712
;Note: modified 20180718 for ENS(90)
;Note: modified 20180725 for ENS(180)
;Note: modified 20190401 for Brunt Vaisala, dtheta/dz


load "/export/home/hongcheq/Programming/NCL/funs_and_procs/funs_and_procs.ncl"

begin
prefix = "/DFS-L/DATA/pritchard/hongcheq/OLD"

chunk = 32
num_time = 96

num1 = new(32,integer)
num2 = new(32,integer)

do i_chunk = 0,chunk-1
num1_temp = i_chunk * num_time/chunk
num2_temp = num1_temp + num_time/chunk - 1

num1(i_chunk) = num1_temp
num2(i_chunk) = num2_temp
end do  ; do i_chunk

;-------------
str_time = new(32,string)
;time_label = new(32,string)

do i_str_time = 0,31
str_time(i_str_time) = "time"+tostring(num1(i_str_time))+"-"+tostring(num2(i_str_time))
;time_label(i_str_time) = "time"+str_time(i_str_time)
end do

;time_label = (/"time0-5","time6-11","time12-17","time18-23","time24-29","time30-35","time36-41","time42-47"/)

;str_time = (/"0-5","6-11","12-17","18-23","24-29","30-35","36-41","42-47"/)

;do index = 0,7
do index = 0,31
;do index = 10,31

TOPO_dir = prefix+"/scratch/hongcheq/HCforcing_sim2_WADA_CTR_TOPO_ENSEMBLE_post-processing_h2_tapes_BruntVaisala/TOPO_TEST/"

TOPO_mean_std = "ENS.std.mean.TOPOTEST.BruntVaisala."+str_time(index)+".nc"

CTR_dir = prefix+"/scratch/hongcheq/HCforcing_sim2_WADA_CTR_TOPO_ENSEMBLE_post-processing_h2_tapes_BruntVaisala/CTR/"

CTR_mean_std = "ENS.std.mean.CTR.BruntVaisala."+str_time(index)+".nc"


f_TOPO = addfile(TOPO_dir+TOPO_mean_std,"r")
f_CTR = addfile(CTR_dir+CTR_mean_std,"r")

var_mean_TOPO = f_TOPO->BV_TOPO_dtheta_dz_mean
var_std_TOPO = f_TOPO->BV_TOPO_dtheta_dz_std

printVarSummary(var_mean_TOPO)
printVarSummary(var_std_TOPO)

var_mean_CTR = f_CTR->BV_CTR_dtheta_dz_mean
var_std_CTR = f_CTR->BV_CTR_dtheta_dz_std

printVarSummary(var_mean_CTR)
printVarSummary(var_std_CTR)

;========== hybrid coordinate to pressure coordinate ====
;pnew = (/50.0,100.0,200.0,300.0,400.0,500.0,600.0,700.0,800.0,850.0,900.0,950.0,1000.0/)
pnew = fspan(100.0,1000.0,200)

P0mb = 1000.0
;printVarSummary(f_TOPO_mean->hyam)
;printVarSummary(f_TOPO_mean->PS)

hyam = f_TOPO->hyam
hybm = f_TOPO->hybm

var_mean_TOPO_pnew = vinth2p(var_mean_TOPO,hyam,hybm,pnew,f_TOPO->PS_TOPO_mean,1,P0mb,1,False)
var_mean_TOPO_pnew&lev_p@units = "hPa" 
;printVarSummary(var_mean_TOPO_pnew&lev_p)

var_std_TOPO_pnew = vinth2p(var_std_TOPO,hyam,hybm,pnew,f_TOPO->PS_TOPO_mean,1,P0mb,1,False)
var_std_TOPO_pnew&lev_p@units = "hPa"
;printVarSummary(var_std_TOPO_pnew)

var_mean_CTR_pnew = vinth2p(var_mean_CTR,hyam,hybm,pnew,f_CTR->PS_CTR_mean,1,P0mb,1,False)
var_mean_CTR_pnew&lev_p@units = "hPa"
;printVarSummary(var_mean_CTR_pnew)
var_std_CTR_pnew = vinth2p(var_std_CTR,hyam,hybm,pnew,f_CTR->PS_CTR_mean,1,P0mb,1,False)
var_std_CTR_pnew&lev_p@units = "hPa"
;printVarSummary(var_std_CTR_pnew)

;----------------------
;-------- convert units from K/m to K/km
var_mean_TOPO_pnew@long_name = "dtheta/dz"
var_mean_CTR_pnew@long_name = "dtheta/dz"

var_mean_TOPO_pnew = var_mean_TOPO_pnew * 1000.0
var_mean_CTR_pnew = var_mean_CTR_pnew * 1000.0

var_mean_TOPO_pnew@units = "K/km"
var_mean_CTR_pnew@units = "K/km"

;---------------
siglvl = 0.1
indep_sample = 180
;========= 180 samples within each ensemble, branched every 10 days, independend number of samples ~ 180
prob = ttest(var_mean_TOPO_pnew,var_std_TOPO_pnew^2,indep_sample,var_mean_CTR_pnew,var_std_CTR_pnew^2,indep_sample,True,False)
;printVarSummary(prob)

; Only retain signals of difference between TOPO and CTR with significance.
diff_TOPO_CTR = var_mean_TOPO_pnew ; metadata
;diff_TOPO_CTR = var_mean_TOPO_pnew - var_mean_CTR_pnew
diff_TOPO_CTR = var_mean_CTR_pnew - var_mean_TOPO_pnew
diff_TOPO_CTR@units = var_mean_TOPO@units
diff_TOPO_CTR@long_name = var_mean_TOPO@long_name

diff_TOPO_CTR_sig = var_mean_TOPO_pnew ; metadata
;diff_TOPO_CTR_sig = where(prob .lt. siglvl,var_mean_TOPO_pnew - var_mean_CTR_pnew,diff_TOPO_CTR@_FillValue)
diff_TOPO_CTR_sig = where(prob .lt. siglvl,var_mean_CTR_pnew - var_mean_TOPO_pnew,diff_TOPO_CTR@_FillValue)
diff_TOPO_CTR_sig@units = var_mean_TOPO@units
diff_TOPO_CTR_sig@long_name = var_mean_TOPO@long_name

;printVarSummary(diff_TOPO_CTR)
;printVarSummary(diff_TOPO_CTR_sig)

BV_dtheta_dz_mean_CTR = var_mean_CTR_pnew
BV_dtheta_dz_diff_TOPO_CTR = diff_TOPO_CTR
BV_dtheta_dz_diff_TOPO_CTR_sig = diff_TOPO_CTR_sig

BV_dtheta_dz_mean_CTR@long_name = "dtheta/da"
BV_dtheta_dz_diff_TOPO_CTR@long_name = "dtheta/dz"
BV_dtheta_dz_diff_TOPO_CTR_sig@long_name = "dtheta/dz"

BV_dtheta_dz_mean_CTR@units = "Kelvin/km"
BV_dtheta_dz_diff_TOPO_CTR@units = "Kelvin/km"
BV_dtheta_dz_diff_TOPO_CTR_sig@units = "Kelvin/km"
;------------------- selection of critical lat and lon
lat_t = 0.0

lon_1 = 260.0
lon_2 = 320.0

;lev_1 = 300.0
lev_1 = 100.0
lev_2 = 1000.0
;----------- Add topography ------
f_TOPO = addfile(prefix+"/scratch/hongcheq/NERSC_Cori_WADA_simulation/F_AMIP_CAM5_WADA_TOPO_1998_sim2_1998-12-01_HCforcing/atm/hist/F_AMIP_CAM5_WADA_TOPO_1998_sim2_1998-12-01_HCforcing.cam.h1.1998-12-05-00000.nc","r")
PHIS = f_TOPO->PHIS
hgt = PHIS(0,{lat_t},{lon_1:lon_2})  ; metadata and dimension
hgt = hgt/9.8
hgt@units = "m"   ; gpm
gp = 1013*(1-6.5/288000*hgt)^5.255  ; convert m to hPa using Standard Atmosphere
gp@units = "hPa"
copy_VarCoords(hgt,gp)
printVarSummary(gp)
;================ plot ===========
;total 6 hrs in the TOPOTEST after branching

total_hrs = 3

plot = new(1,graphic)
plot_sig = new(1,graphic)

do i_hr = 0,total_hrs-1
;do i_day = 0,3

wks = gsn_open_wks("png","../Figures/4_EQ_to100hPa_BV_dtheta_dz_TOPO_vs_CTR_ihr_"+tostring(index*3+i_hr+1))
wks_sig = gsn_open_wks("png","../Figures/4_Sig_EQ_to100hPa_BV_dtheta_dz_TOPO_vs_CTR_ihr_"+tostring(index*3+i_hr+1))

res = True
res@gsnDraw = False
res@gsnFrame = False
res@cnLinesOn = False
res@cnLineLabelsOn = False
res@cnFillOn = True

res@cnLevelSelectionMode = "ManualLevels"
res@cnMinLevelValF = -2.0
res@cnMaxLevelValF = 2.0
res@cnLevelSpacingF = 0.1

plot(0) = gsn_csm_pres_hgt(wks,BV_dtheta_dz_diff_TOPO_CTR(i_hr,{lev_1:lev_2},{lat_t},{lon_1:lon_2}),res)
plot_sig(0) = gsn_csm_pres_hgt(wks_sig,BV_dtheta_dz_diff_TOPO_CTR_sig(i_hr,{lev_1:lev_2},{lat_t},{lon_1:lon_2}),res)

;------add topography ----
mres   = True
mres@gsnLeftString       = " "
mres@gsnRightString      = " "
mres@gsnDraw             = False                ; do not draw the plot
mres@gsnFrame            = False                ; do not advance the frame
mres@xyLineThicknesses   = (/3.0/)              ; make line thicker
mres@xyLineColors        = (/"black"/)          ; change line color

mres@gsnBelowYRefLineColor = (/ "black", "black"/)  
mres@gsnYRefLine           = (/ lev_1 ,lev_2 /)   

plot_topo2  = gsn_csm_xy(wks,gp&lon,gp,mres)         ; overlay geopotential 'pressure' line
plot_topo2_sig = gsn_csm_xy(wks_sig,gp&lon,gp,mres)
overlay(plot(0),plot_topo2)
overlay(plot_sig(0),plot_topo2_sig)
;draw(plot)
;frame(wks)
 
;============ panel plot ====

str_LST = (/"20:00","21:00","22:00","23:00","24:00","01:00","02:00","03:00","04:00","05:00","06:00","07:00","08:00","09:00","10:00","11:00","12:00","13:00","14:00","15:00","16:00","17:00","18:00","19:00"/)

pres = True
pres@txString = "CTR - TOPO, ENS(180), ihr="+tostring(index*3+i_hr+1) +", LST_75W ("+str_LST(mod(index*3+i_hr,24))+")"+", lat="+sprintf("%5.1f",lat_t)

gsn_panel(wks,plot,(/1,1/),pres)

gsn_panel(wks_sig,plot_sig,(/1,1/),pres)


end do ; do i_day 

end do ; do index

end
