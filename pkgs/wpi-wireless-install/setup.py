#!/usr/bin/env python

from setuptools import find_packages, setup

setup(
    name="wpi-wireless-install",
    version="0.1",
    packages=find_packages(),
    package_data={'wpi_wireless_install': ['SecureW2.cloudconfig']},
    entry_points={
        "console_scripts": ["wpi-wireless-install = wpi_wireless_install.main:run"]
    },
    install_requires=["dbus-python"],
)
