*&---------------------------------------------------------------------*
*& Report ZABAP_D0711_FLIGHT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zabap_d0711_flight.

DATA :
BEGIN OF gs_list,
  carrid TYPE sflight-carrid,
  carrname TYPE scarr-carrname,
  connid TYPE sflight-connid,
  cityfrom TYPE spfli-cityfrom,
  cityto TYPE spfli-cityto,
  fldate TYPE sflight-fldate,
  price TYPE sflight-price,
  currency TYPE sflight-currency,
  seatsmax TYPE sflight-seatsmax,
  seatsocc TYPE sflight-seatsocc,
  seatsremain TYPE sflight-seatsmax,
  seatsmax_b TYPE sflight-seatsmax_b,
  seatsocc_b TYPE sflight-seatsocc_b,
  seatsremain_b TYPE sflight-seatsmax_b,
  seatsmax_f TYPE sflight-seatsmax_f,
  seatsocc_f TYPE sflight-seatsocc_f,
  seatsremain_f TYPE sflight-seatsmax_f,
END OF gs_list.

*DATA : GS_LIST TYPE SFLIGHT.
DATA : gt_list LIKE TABLE OF gs_list.

PARAMETERS pa_car TYPE s_carr_id.
SELECT-OPTIONS so_con FOR gs_list-connid.
SELECT-OPTIONS so_dat FOR gs_list-fldate.

INITIALIZATION.

pa_car = 'AA'.

so_con-sign = 'I'.
so_con-option = 'BT'.
so_con-low = 0.
so_con-high = 90.
APPEND so_con.

so_dat-sign = 'I'.
so_dat-option = 'BT'.
so_dat-low = '20200101'.
so_dat-high = sy-datum.
APPEND so_dat.

AT SELECTION-SCREEN.
  IF pa_car = 'LH'.
    MESSAGE e000(zmd07).
  ENDIF.

START-OF-SELECTION.

*2. SFLIGHT Table에서 기본적으로 제공될 Flight List Info를 취득해서 데이터를 보여준다.

SELECT *
  FROM sflight
  INTO CORRESPONDING FIELDS OF TABLE gt_list
  WHERE carrid = pa_car
  AND connid IN so_con
  AND fldate IN so_dat.

*3. SCARR Table에서 CARRNAME를 취득해서 데이터를 보여준다.

LOOP AT gt_list INTO gs_list.
  SELECT SINGLE carrname
    FROM scarr
    INTO CORRESPONDING FIELDS OF gs_list.
  MODIFY gt_list FROM gs_list TRANSPORTING carrname.
ENDLOOP.

*4. SPFLI Table에서 CITYFROM, CITYTO를 취득해서 데이터를 보여준다.

LOOP AT gt_list INTO gs_list.
  SELECT SINGLE cityfrom cityto
    FROM spfli
    INTO CORRESPONDING FIELDS OF gs_list.
  MODIFY gt_list FROM gs_list TRANSPORTING cityfrom cityto.
ENDLOOP.

*SELECT b~cityfrom b~cityto
*  FROM sflight AS a
*  LEFT JOIN spfli AS b
*  ON a~carrid = b~carrid
*  INTO ( gs_list-cityfrom , gs_list-cityto ).
*ENDSELECT.


*7. 필요하다고 생각되는 부분을 Subroutine으로 적용한다.
PERFORM get_remain USING gs_list-seatsmax
                         gs_list-seatsocc
                CHANGING gs_list-seatsremain.

PERFORM get_remain_b USING gs_list-seatsmax_b
                           gs_list-seatsocc_b
                  CHANGING gs_list-seatsremain_b.

PERFORM get_remain_f USING gs_list-seatsmax_f
                           gs_list-seatsocc_f
                  CHANGING gs_list-seatsremain_f.

*6. 특별 상황을 적용한다.
*1) 입력한 조건 값에 따라서 일치하는 데이터가 없는 경우 ‘Data is not found’ 메시지를 보여준다.
IF sy-subrc = 0.
ELSEIF sy-subrc = 2.
  MESSAGE  i001(zmd07).
ELSEIF sy-subrc = 4.
  MESSAGE  i002(zmd07).
ENDIF.


cl_demo_output=>display( gt_list ).


FORM get_remain  USING VALUE(PV_seatsmax)
                       VALUE(PV_seatsocc)
              CHANGING VALUE(CV_seatsremain).

 LOOP AT gt_list INTO gs_list.
CALL FUNCTION 'ZD07_SEATSREMAIN'
  EXPORTING
    iv_seatsmax          =  gs_list-seatsmax
    iv_seatsocc          = gs_list-seatsocc
  IMPORTING
   ev_seatsremain       = gs_list-seatsremain
  EXCEPTIONS
*2) SEATSOCC이 ‘0’이면, 모든 남은 좌석은 0으로 표시한다.
   zero_error           = 1
   OTHERS               = 2
          .
  IF sy-subrc <> 0.

ENDIF.
 MODIFY gt_list FROM gs_list TRANSPORTING seatsremain.
ENDLOOP.

ENDFORM.

FORM get_remain_b  USING VALUE(PV_seatsmax_b)
                         VALUE(PV_seatsocc_b)
                CHANGING VALUE(CV_seatsremain_b).

 LOOP AT gt_list INTO gs_list.
CALL FUNCTION 'ZD07_SEATSREMAIN'
  EXPORTING
    iv_seatsmax          =  gs_list-seatsmax_b
    iv_seatsocc          = gs_list-seatsocc_b
  IMPORTING
   ev_seatsremain       = gs_list-seatsremain_b
  EXCEPTIONS
   zero_error           = 1
   OTHERS               = 2
          .
  IF sy-subrc <> 0.

ENDIF.
 MODIFY gt_list FROM gs_list TRANSPORTING seatsremain_b.
ENDLOOP.

ENDFORM.

FORM get_remain_f  USING VALUE(PV_seatsmax_f)
                         VALUE(PV_seatsocc_f)
                CHANGING VALUE(CV_seatsremain_f).

 LOOP AT gt_list INTO gs_list.
CALL FUNCTION 'ZD07_SEATSREMAIN'
  EXPORTING
    iv_seatsmax          =  gs_list-seatsmax_f
    iv_seatsocc          = gs_list-seatsocc_f
  IMPORTING
   ev_seatsremain       = gs_list-seatsremain_f
  EXCEPTIONS
   zero_error           = 1
   OTHERS               = 2
          .
  IF sy-subrc <> 0.

ENDIF.
 MODIFY gt_list FROM gs_list TRANSPORTING seatsremain_f.
ENDLOOP.

ENDFORM.
