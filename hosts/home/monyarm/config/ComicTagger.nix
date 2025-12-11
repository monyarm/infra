{ lib, ... }:
{
  home.file.".ComicTagger/settings".text = lib.generators.toINI { } {
    settings = {
      check_for_new_version = false;
      rar_exe_path = "";
      unrar_lib_path = "";
      send_usage_stats = false;
    };
    auto = {
      install_id = "ffb992f59c2f4f0ea65698f59c27b49f";
      last_selected_load_data_style = 0;
      last_selected_save_data_style = 1;
      last_opened_folder = "/home/monyarm/Ebook/Comic";
      last_main_window_width = 1740;
      last_main_window_height = 687;
      last_main_window_x = 167;
      last_main_window_y = 241;
      last_form_side_width = 1234;
      last_list_side_width = 478;
      last_filelist_sorted_column = -1;
      last_filelist_sorted_order = 0;
    };
    identifier = {
      id_length_delta_thresh = 5;
      id_publisher_blacklist = lib.concatStringsSep ", " [
        "Panini Comics"
        "Abril"
        "Planeta DeAgostini"
        "Editorial Televisa"
        "Dino Comics"
      ];
    };
    dialogflags = {
      ask_about_cbi_in_rar = true;
      show_disclaimer = true;
      dont_notify_about_this_version = "";
      ask_about_usage_stats = true;
      show_no_unrar_warning = true;
    };
    filenameparser = {
      parse_scan_info = true;
    };
    comicvine = {
      use_series_start_as_volume = false;
      clear_form_before_populating_from_cv = false;
      remove_html_tables = false;
      cv_api_key = "";
    };
    cbl_transform = {
      assume_lone_credit_is_primary = false;
      copy_characters_to_tags = false;
      copy_teams_to_tags = false;
      copy_locations_to_tags = false;
      copy_storyarcs_to_tags = false;
      copy_notes_to_comments = false;
      copy_weblink_to_comments = false;
      apply_cbl_transform_on_cv_import = false;
      apply_cbl_transform_on_bulk_operation = false;
    };
    rename = {
      rename_template = "%series% #%issue% (%year%)";
      rename_issue_number_padding = 3;
      rename_use_smart_string_cleanup = true;
      rename_extension_based_on_archive = true;
    };
    autotag = {
      save_on_low_confidence = false;
      dont_use_year_when_identifying = false;
      assume_1_if_no_issue_num = false;
      ignore_leading_numbers_in_filename = false;
      remove_archive_after_successful_match = false;
      wait_and_retry_on_rate_limit = false;
    };
  };
}
