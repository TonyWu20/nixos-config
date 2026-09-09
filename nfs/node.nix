{ ... }: {
  fileSystems = {
    "/export" = {
      device = "10.0.0.6:/";
      fsType = "nfs";
      options = [ "nofail" ];
    };
    "/export/castep_jobs" = {
      device = "10.0.0.6:/castep_jobs";
      fsType = "nfs";
      options = [ "nofail" ];
    };
    "/export/g16" = {
      device = "10.0.0.6:/g16";
      fsType = "nfs";
      options = [ "nofail" ];
    };
    "/export/gauss_shell" = {
      device = "10.0.0.6:/gauss_shell";
      fsType = "nfs";
      options = [ "nofail" ];
    };
    "/export/gaussian_jobs" = {
      device = "10.0.0.6:/gaussian_jobs";
      fsType = "nfs";
      options = [ "nofail" ];
    };
    "/export/Potentials" = {
      device = "10.0.0.6:/Potentials";
      fsType = "nfs";
      options = [ "nofail" ];
    };
    "/export/public_castep_jobs" = {
      device = "10.0.0.6:/public_castep_jobs";
      fsType = "nfs";
      options = [ "nofail" ];
    };
    "/export/lammps_jobs" = {
      device = "10.0.0.6:/lammps_jobs";
      fsType = "nfs";
      options = [ "nofail" ];
    };
    "/export/castep-rust-eigensolve" = {
      device = "10.0.0.6:/castep-rust-eigensolve";
      fsType = "nfs";
      options = [ "rw" "noauto" "x-systemd.automount" "nofail" ];
    };
  };
}
