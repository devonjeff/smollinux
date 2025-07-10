<h1 align=center>Smollinux!</h1>
<p align=center>A fully <b>from-scratch</b> minimal Linux system, designed to be simple, it works, and reliable.</p>

---

## 📌 Project Goals

- Build everything **from source**, no base distro
- Produce a minimal, bootable system
- Make the entire build process **scripted and reproducible**
- Keep track of all patches, sources, and build logs
- Include a package manager for expansion (later)

---

## ⚙️ Directory Structure
1. Initramfs
<pre>
├── bin
│   ├── blkid -> busybox
│   ├── cat -> busybox
│   ├── cut -> busybox
│   ├── echo -> busybox
│   ├── grep -> busybox
│   ├── ls -> busybox
│   ├── mkdir -> busybox
│   ├── mount -> busybox
│   ├── seq -> busybox
│   ├── sh -> busybox
│   ├── sleep -> busybox
│   └── switch_root -> busybox
├── dev
│   ├── console
│   └── null
├── init
├── lib64
├── newroot
├── proc
├── sys
└── usr
</pre>

---

## 🗂️ Directories Explained

- **/initramfs/**  
  - Contains the initial RAM filesystem structure and files
  - This is what loads during early boot before the main system is mounted
  - Contains the `init` script that handles early boot process
  - Includes symlinks to BusyBox for essential utilities
- **/build/**
  - Contains output files
  - Includes system images (rootfs.img), compressed initramfs (initramfs.cpio.gz),
    and other generated files
  - All reproducible build outputs are stored here 
- **/sources/**
  - Contains directories for each package or source (eg: /sources/busybox-x.xx.x /sources/glibc-x.xx)
  - Each package is built, configured from here
- **/sources/build/**
  - Build directory for sources that require out-of-tree builds
  - Example: /sources/build/glibc for packages that need a separate build directory
- **/sources/install/**
  - Install directory for packages before final deployment
  - Files are extracted from here to rootfs or initramfs as needed
- **/temp/**
  - Temporary storage for downloaded packages or source tarballs
  - Cleaned between builds to ensure reproducibility

---

## 🚀 Build Process

The system is built in reproducible stages:

1. **The initramfs**
   - Create basic directory structure in $WORKDIR/initramfs (bin, dev, lib64, newroot, proc, sys, usr)
   - Generate the init script that handles early boot process
   - Set up essential utilities through busybox symlinks (blkid, cat, cut, echo, grep, ls, mkdir, mount, seq, sh, sleep, switch_root)
   - Configure necessary device nodes for system boot:
     - Create console device (character device 5:1) with mode 600
     - Create null device (character device 1:3) with mode 666
     - These special files are required for basic system functionality

---

## 🛠️ Requirements

- Not defined yet

---

## 🤝 Contributing

- Fork and PR improvements.
- Log issues for bugs or questions.
- Keep all build steps **fully scripted**.

---

## 📜 License

This project is licensed under the GNU General Public License v3.0 (see [LICENSE](LICENSE))

---

## 🌐 References

- [Linux From Scratch](https://www.linuxfromscratch.org/lfs/view/stable/)
- [Beyond Linux From Scratch](https://www.linuxfromscratch.org/blfs/view/stable/)
