{ ... }: {
  programs.tofi = {
    enable = true;
    settings = {
      font-size = 10;
      # Frappe
      text-color = "#c6d0f5";
      prompt-color = "#e78284";
      selection-color = "#e5c890";
      background-color = "#303446";
      border-color = "#303446";
      input-color = "#ca9ee6";
      outline-width = "0";
      border-width = "0";
      corner-radius = "0";
      scale = "true";
      width = "100%";
      height = "30";
      # dmenu theme
      anchor = "top-left";
      min-input-width = "120";
      horizontal = "true";
      result-spacing = "15";
      prompt-padding = "10";
      padding-top = "0";
      padding-bottom = "0";
      padding-left = "0";
      padding-right = "0";
    };
  };

}
