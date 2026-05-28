# Quick verification runner: run a 1-epoch training to smoke-test the training pipeline
import os
import sys

# Ensure the scripts directory is in sys.path so train_model can be imported
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

import train_model as tm

if __name__ == '__main__':
    print('Setting EPOCHS=1 for quick verification')
    tm.EPOCHS = 1
    tm.train_model(tm.DATA_PATH)

