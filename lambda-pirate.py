import subprocess
import logfmt
import os

VMSH = "./vmsh/vmsh/bin/vmsh"
BUSYBOX = "./vmsh/busybox.rw.ext4"

# BUSYBOX_CMD = ["/bin/ls", "-la"]
BUSYBOX_CMD = ["/bin/sh"]

def await_error() -> int:
    cmd = subprocess.Popen(["journalctl", "-f", "--no-pager", "-o", "cat", "-n", "0", "-u", "vhive"], stdout=subprocess.PIPE)
    while True:
        line = cmd.stdout.readline().decode()
        line = logfmt.parse_line(line)
        keys = line.keys()
        if "msg" in keys and "vmID" in keys and "ERROR" in line["msg"]:
            vmID = line["vmID"]
            msg = line["msg"].strip()
            # TODO add a pod_name and namespace field in vhive to display here
            print(f"[VM {vmID} error] {msg}")
            return vmID


def attach_vmsh(vmID: int) -> None:
    pts = os.readlink(f"/proc/self/fd/0")
    print(f"--pts {pts}")
    argv = [
        VMSH, 
        "attach", 
        "-t", 
        "vhive_fc_vmid", 
        "-f", 
        BUSYBOX, 
        "--pts" , 
        str(pts), 
        str(vmID), 
        "--", 
    ]
    argv += BUSYBOX_CMD
    cmd = subprocess.Popen(argv)
    cmd.wait()
    

def main() -> None:
    print("lambda-pirate deamon for vhive")
    print("Waiting for errors in vhive workloads. ")
    vmID = await_error()
    print(f"attaching vmsh to VM {vmID}")
    attach_vmsh(vmID)


if __name__ == "__main__":
    main()

