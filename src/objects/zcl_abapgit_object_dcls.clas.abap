CLASS zcl_abapgit_object_dcls DEFINITION PUBLIC INHERITING FROM zcl_abapgit_objects_super FINAL.

  PUBLIC SECTION.
    INTERFACES zif_abapgit_object.
    METHODS constructor
      IMPORTING
        is_item        TYPE zif_abapgit_definitions=>ty_item
        iv_language    TYPE spras
        io_files       TYPE REF TO zcl_abapgit_objects_files OPTIONAL
        io_i18n_params TYPE REF TO zcl_abapgit_i18n_params OPTIONAL
      RAISING
        zcx_abapgit_type_not_supported.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_abapgit_object_dcls IMPLEMENTATION.

  METHOD constructor.

    DATA: lo_dcl TYPE REF TO object.

    super->constructor(
        is_item        = is_item
        iv_language    = iv_language
        io_files       = io_files
        io_i18n_params = io_i18n_params ).

    TRY.
        CALL METHOD ('CL_ACM_DCL_HANDLER_FACTORY')=>('CREATE')
          RECEIVING
            ro_handler = lo_dcl.

      CATCH cx_sy_ref_creation.
        RAISE EXCEPTION TYPE zcx_abapgit_type_not_supported EXPORTING obj_type = is_item-obj_type.
    ENDTRY.

  ENDMETHOD.


  METHOD zif_abapgit_object~changed_by.
    DATA: lr_data  TYPE REF TO data,
          lo_dcl   TYPE REF TO object,
          lx_error TYPE REF TO cx_root.

    FIELD-SYMBOLS: <lg_data>  TYPE any,
                   <lg_field> TYPE any.

    CREATE DATA lr_data TYPE ('ACM_S_DCLSRC').
    ASSIGN lr_data->* TO <lg_data>.

    TRY.
        CALL METHOD ('CL_ACM_DCL_HANDLER_FACTORY')=>('CREATE')
          RECEIVING
            ro_handler = lo_dcl.

        CALL METHOD lo_dcl->('READ')
          EXPORTING
            iv_dclname = ms_item-obj_name
          IMPORTING
            es_dclsrc  = <lg_data>.

        ASSIGN COMPONENT 'AS4USER' OF STRUCTURE <lg_data> TO <lg_field>.
        IF sy-subrc = 0.
          rv_user = <lg_field>.
        ELSE.
          rv_user = c_user_unknown.
        ENDIF.
      CATCH cx_root INTO lx_error.
        zcx_abapgit_exception=>raise_with_text( lx_error ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_abapgit_object~delete.

    DATA: lo_dcl   TYPE REF TO object,
          lx_error TYPE REF TO cx_root.

    TRY.
        CALL METHOD ('CL_ACM_DCL_HANDLER_FACTORY')=>('CREATE')
          RECEIVING
            ro_handler = lo_dcl.

        CALL METHOD lo_dcl->('DELETE')
          EXPORTING
            iv_dclname = ms_item-obj_name.

      CATCH cx_root INTO lx_error.
        zcx_abapgit_exception=>raise_with_text( lx_error ).
    ENDTRY.

    corr_insert( iv_package ).

  ENDMETHOD.


  METHOD zif_abapgit_object~deserialize.

    DATA: lr_data                  TYPE REF TO data,
          lo_dcl                   TYPE REF TO object,
          lx_error                 TYPE REF TO cx_root,
          lv_abap_language_version TYPE uccheck.

    FIELD-SYMBOLS: <lg_data>  TYPE any,
                   <lg_field> TYPE any.


    CREATE DATA lr_data TYPE ('ACM_S_DCLSRC').
    ASSIGN lr_data->* TO <lg_data>.

    io_xml->read(
      EXPORTING
        iv_name = 'DCLS'
      CHANGING
        cg_data = <lg_data> ).

    ASSIGN COMPONENT 'SOURCE' OF STRUCTURE <lg_data> TO <lg_field>.
    ASSERT sy-subrc = 0.
    <lg_field> = mo_files->read_string( 'asdcls' ).

    ASSIGN COMPONENT 'ABAP_LANGUAGE_VERSION' OF STRUCTURE <lg_data> TO <lg_field>.
    IF sy-subrc = 0.
      lv_abap_language_version = <lg_field>.
      set_abap_language_version( CHANGING cv_abap_language_version = lv_abap_language_version ).
    ENDIF.

    TRY.
        tadir_insert( iv_package ).

        CALL METHOD ('CL_ACM_DCL_HANDLER_FACTORY')=>('CREATE')
          RECEIVING
            ro_handler = lo_dcl.

        TRY.
            CALL METHOD lo_dcl->('SAVE')
              EXPORTING
                iv_dclname               = ms_item-obj_name
                iv_put_state             = 'I'
                is_dclsrc                = <lg_data>
                iv_devclass              = iv_package
                iv_access_mode           = 'INSERT'
                iv_abap_language_version = lv_abap_language_version.
          CATCH cx_sy_dyn_call_param_not_found.
            CALL METHOD lo_dcl->('SAVE')
              EXPORTING
                iv_dclname     = ms_item-obj_name
                iv_put_state   = 'I'
                is_dclsrc      = <lg_data>
                iv_devclass    = iv_package
                iv_access_mode = 'INSERT'.
        ENDTRY.

      CATCH cx_root INTO lx_error.
        zcx_abapgit_exception=>raise_with_text( lx_error ).
    ENDTRY.

    zcl_abapgit_objects_activation=>add_item( ms_item ).

  ENDMETHOD.


  METHOD zif_abapgit_object~exists.

    DATA: lo_dcl   TYPE REF TO object,
          lx_error TYPE REF TO cx_root.

    TRY.
        CALL METHOD ('CL_ACM_DCL_HANDLER_FACTORY')=>('CREATE')
          RECEIVING
            ro_handler = lo_dcl.

        CALL METHOD lo_dcl->('CHECK_EXISTENCE')
          EXPORTING
            iv_objectname = ms_item-obj_name
          RECEIVING
            rv_exists     = rv_bool.

      CATCH cx_root INTO lx_error.
        zcx_abapgit_exception=>raise_with_text( lx_error ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_abapgit_object~get_comparator.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_object~get_deserialize_order.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_object~get_deserialize_steps.
    APPEND zif_abapgit_object=>gc_step_id-late TO rt_steps.
  ENDMETHOD.


  METHOD zif_abapgit_object~get_metadata.
    rs_metadata = get_metadata( ).
  ENDMETHOD.


  METHOD zif_abapgit_object~is_active.
    rv_active = is_active( ).
  ENDMETHOD.


  METHOD zif_abapgit_object~is_locked.

    rv_is_locked = exists_a_lock_entry_for( iv_lock_object = 'E_ACMDCLSRC'
                                            iv_argument    = |{ ms_item-obj_name }| ).

  ENDMETHOD.


  METHOD zif_abapgit_object~jump.
    " Covered by ZCL_ABAPGIT_ADT_LINK=>JUMP
  ENDMETHOD.


  METHOD zif_abapgit_object~map_filename_to_object.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_object~map_object_to_filename.
    RETURN.
  ENDMETHOD.


  METHOD zif_abapgit_object~serialize.

    DATA: lr_data  TYPE REF TO data,
          lo_dcl   TYPE REF TO object,
          lx_error TYPE REF TO cx_root.

    FIELD-SYMBOLS: <lg_data>  TYPE any,
                   <lg_field> TYPE any.


    CREATE DATA lr_data TYPE ('ACM_S_DCLSRC').
    ASSIGN lr_data->* TO <lg_data>.

    TRY.
        CALL METHOD ('CL_ACM_DCL_HANDLER_FACTORY')=>('CREATE')
          RECEIVING
            ro_handler = lo_dcl.

        CALL METHOD lo_dcl->('READ')
          EXPORTING
            iv_dclname = ms_item-obj_name
          IMPORTING
            es_dclsrc  = <lg_data>.

        ASSIGN COMPONENT 'AS4USER' OF STRUCTURE <lg_data> TO <lg_field>.
        ASSERT sy-subrc = 0.
        CLEAR <lg_field>.

        ASSIGN COMPONENT 'AS4DATE' OF STRUCTURE <lg_data> TO <lg_field>.
        ASSERT sy-subrc = 0.
        CLEAR <lg_field>.

        ASSIGN COMPONENT 'AS4TIME' OF STRUCTURE <lg_data> TO <lg_field>.
        ASSERT sy-subrc = 0.
        CLEAR <lg_field>.

        ASSIGN COMPONENT 'CREATED_BY' OF STRUCTURE <lg_data> TO <lg_field>.
        ASSERT sy-subrc = 0.
        CLEAR <lg_field>.

        ASSIGN COMPONENT 'CREATED_DATE' OF STRUCTURE <lg_data> TO <lg_field>.
        ASSERT sy-subrc = 0.
        CLEAR <lg_field>.

        ASSIGN COMPONENT 'AS4LOCAL' OF STRUCTURE <lg_data> TO <lg_field>.
        ASSERT sy-subrc = 0.
        CLEAR <lg_field>.

        ASSIGN COMPONENT 'ABAP_LANGUAGE_VERSION' OF STRUCTURE <lg_data> TO <lg_field>.
        IF sy-subrc = 0.
          clear_abap_language_version( CHANGING cv_abap_language_version = <lg_field> ).
        ENDIF.

        ASSIGN COMPONENT 'SOURCE' OF STRUCTURE <lg_data> TO <lg_field>.
        ASSERT sy-subrc = 0.

        mo_files->add_string(
          iv_ext    = 'asdcls'
          iv_string = <lg_field> ).

        CLEAR <lg_field>.

        io_xml->add( iv_name = 'DCLS'
                     ig_data = <lg_data> ).

      CATCH cx_root INTO lx_error.
        zcx_abapgit_exception=>raise_with_text( lx_error ).
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
