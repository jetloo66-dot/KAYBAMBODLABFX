"""Setup script for KAYBAMBODLABFX Bot Framework."""

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="kaybambodlabfx",
    version="1.0.0",
    author="KAYBAMBODLABFX Team", 
    author_email="team@kaybambodlabfx.com",
    description="A comprehensive bot framework for problem solving and task automation",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/jetloo66-dot/KAYBAMBODLABFX",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
    ],
    python_requires=">=3.8",
    install_requires=[
        # Core framework has no external dependencies
        # Uses only Python standard library for maximum compatibility
    ],
    extras_require={
        "full": [
            "requests>=2.28.0",
            "schedule>=1.2.0", 
            "click>=8.0.0",
            "pydantic>=1.10.0",
            "aiohttp>=3.8.0",
            "python-dateutil>=2.8.0",
        ],
        "web": [
            "requests>=2.28.0",
            "aiohttp>=3.8.0",
        ],
        "scheduling": [
            "schedule>=1.2.0",
            "python-dateutil>=2.8.0",
        ],
        "cli": [
            "click>=8.0.0",
        ],
        "validation": [
            "pydantic>=1.10.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "kaybambodlabfx=main:main",
            "kbl=main:main",
        ],
    },
    project_urls={
        "Bug Reports": "https://github.com/jetloo66-dot/KAYBAMBODLABFX/issues",
        "Source": "https://github.com/jetloo66-dot/KAYBAMBODLABFX",
        "Documentation": "https://github.com/jetloo66-dot/KAYBAMBODLABFX/wiki",
    },
)