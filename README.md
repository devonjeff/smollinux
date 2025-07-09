<h1 align=center>Smollinux</h1>
<p align=center>A fully <b>from-scratch</b> minimal Linux system, designed to be simple, it works, and reliable.</p>

---

## 📌 Project Goals

- Build everything **from source**, no base distro
- Produce a minimal, bootable system
- Make the entire build process **scripted and reproducible**
- Keep track of all patches, sources, and build logs
- Include a package manager for expansion (later)

---

## ⚙️ Project Structure
(Not decided yet)

---

## 🗂️ Directories Explained

- **/initramfs/**  
  - Contains the initial RAM filesystem structure and files
  - This is what loads during early boot before the main system is mounted
- **/build/**
  - Contains output files
  - Includes system images (rootfs.img), compressed initramfs (initramfs.cpio.gz),
    and other generated files
  - All reproducible build outputs are stored here 

---

## 🚀 Build Process

The system is built in reproducible stages:

1. **Example one**
   - It's an Example!

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

This project is licensed under the ? (see LICENSE).

---

## 🌐 References

- [Linux From Scratch](https://www.linuxfromscratch.org/lfs/view/stable/)
- [Beyond Linux From Scratch](https://www.linuxfromscratch.org/blfs/view/stable/)
