{ pkgs, ... }: {
  services.slurm = {
    server.enable = true;
  };
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;

    ensureDatabases = [ "slurm_acct_db" ];
    ensureUsers = [{
      ensurePermissions = { "slurm_acct_db.*" = "ALL PRIVILEGES"; };
      name = "slurm";
    }];

    settings.mysqld = {
      bind-address = "localhost";

      # recommendations from: https://slurm.schedmd.com/accounting.html#mysql-configuration
      innodb_buffer_pool_size = "1024M";
      innodb_log_file_size = "64M";
      innodb_lock_wait_timeout = 900;
    };
  };

}
