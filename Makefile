THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 22
ARCHS = arm64
TARGET = iphone:latest:8.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = EsperLLSIF
EsperLLSIF_FILES = Tweak.xm

EsperLLSIF_CFLAGS += -std=c++11

include $(THEOS_MAKE_PATH)/tweak.mk

after-clean::
	rm -rf ./.theos ./obj ./packages