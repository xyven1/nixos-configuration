#!/usr/bin/env python

from setuptools import find_packages, setup

setup(
    name="wpi-wireless-install",
    version="0.1",
    packages=find_packages(),
    include_package_data=True,
    entry_points={
        "console_scripts": ["wpi-wireless-install = wpi_wireless_install.main:run"]
    },
    install_requires=["dbus-python"],
)
