SET(SOURCES screens/ui_Medical_Screen.c
    ui.c
    components/ui_comp_hook.c
    ui_helpers.c
    ui_events.c
    images/ui_img_img_heart_small_png.c
    images/ui_img_icn_history_png.c
    images/ui_img_icn_battery_png.c
    images/ui_img_icn_bluetooth_png.c
    images/ui_img_img_slider_png.c
    images/ui_img_img_line_png.c
    images/ui_img_img_heart_big_png.c
    images/ui_img_img_btn_bg_png.c
    images/ui_img_img_btn_off_png.c
    images/ui_img_img_btn_on_png.c
    images/ui_img_img_switch_bg_png.c
    fonts/ui_font_Big_Number.c
    fonts/ui_font_Bold_Font.c)

add_library(ui ${SOURCES})
