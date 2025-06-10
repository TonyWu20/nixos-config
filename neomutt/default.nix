{ ... }: {

  accounts.email = {
    accounts = {
      gmail = {
        primary = true;
        address = "tony.w21@gmail.com";
        userName = "tony.w21@gmail.com";
        realName = "Tony";
        flavor = "gmail.com";
        passwordCommand = "echo uwjuwjpjmynvyzww";
        imap = {
          host = "imap.gmail.com";
          port = 993;
          tls.useStartTls = true;
        };
        smtp = {
          host = "smtp.gmail.com";
          port = 465;
        };
        neomutt = {
          enable = true;
          mailboxType = "imap";
          extraConfig = "
#Gmail
set imap_user = \"tony.w21@gmail.com\"
set smtp_authenticators = 'gssapi:login'

# Ensure TLS is enforced
set ssl_starttls = yes
set ssl_force_tls=yes

# My mailboxes
# set folder = \"imaps://imap.gmail.com:993/[Gmail]\"
set spoolfile = +INBOX
set postponed = \"+[Gmail]/Drafts\"
set record = \"+[Gmail]/Sent Mail\"

mailboxes =INBOX =[Gmail]/Sent\\ Mail =[Gmail]/Starred =[Gmail]/Drafts  =[Gmail]/Spam =[Gmail]/Trash

# Where to put the stuff
set header_cache = \"$XDG_CACHE_HOME/mutt/headers\"
set message_cachedir = \"$XDG_CACHE_HOME/mutt/bodies\"
set certificate_file = \"$XDG_CACHE_HOME/mutt/certificates\"
unset record
      ";
        };
      };
    };
  };
  programs.neomutt = {
    enable = true;
    editor = "nvim";
    vimKeys = true;
    extraConfig = builtins.readFile ./muttrc;
  };
}
