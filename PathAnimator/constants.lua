-- Path Animator Tool Constants
-- Copyright (C) 2020 Gaspar Capello

STRING_PATH_LAYER = "PATH"
STRING_RESULT_LAYER = "ResultLayer"
STRING_FUNCTION_LAYER = "TFUN"
STRING_ROTATION_LAYER = "RFUN"
STRING_LOOKED_LAYER = "LOOKIT"
STRING_ROTAUX_LAYER = "RotAux"

FUNC_LINEAL = "Lineal"
FUNC_BYLAYER = "By Layer"
FUNC_EASYIN = "Easy In"
FUNC_EASYOUT = "Easy Out"
FUNC_EASYINOUT = "Easy InOut"
FUNC_SINUSOIDAL = "Sinusoidal"
FUNC_PARABOLIC = "Parabolic"
FUNC_EASYOUTDAMPED = "Easy Out Damped"
FUNC_EASYOUTDAMPED2 = "Easy Out Damped2"

ROTATION_NONE = "None"
ROTATION_PATH = "Path track"
ROTATION_LOOKAT = "Look at"
ROTATION_BYLAYER = "By Layer"

DEFAULT_STARTTIME_STRING = "Start_time_[seg]"
DEFAULT_DURATION_STRING = "Duration_[seg]"
DEFAULT_INITIALANGLE_STRING = "Start_angle_[degrees]"
DEFAULT_PATH_START_POS_STRING = "Start_path_pos_[%]"
DEFAULT_LOOP_PATH = false
DEFAULT_MAKE_NEW_RESULT_LAYER = true

TFUNprefix = "Translation: "
ROTATIONprefix = "Rotation: "
LOOP_PHASE = "Loop the path translation?"

-- K_PATH_TO_IMAGE_CONSTANT
-- Towards 0.0 (minimum in practice 0.2) angles ares more tangencial to the path curve, but low angle resolution is obtained.
-- In thr other hand, K_PATH_TO_IMAGE_CONSTANT towards 1.0, is like a wagon on a railways,
-- the middle axis of the image will be secant on two points on the path ccurves
K_PATH_TO_IMAGE_CONSTANT = 0.75

MASK_COLOR2 = 0x007f7f7f