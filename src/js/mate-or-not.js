/*
 * Copyright 2017 Christian Murphy
 * Released under the MIT license
 */
import {Chessboard, FEN, COLOR} from "./cm-chessboard/Chessboard.js";

let POSITION_PAIRS = [];

async function loadPositions() {
  try {
    const response = await fetch('./js/position-pairs.json');
    POSITION_PAIRS = await response.json();
  } catch (error) {
    console.error('Error loading positions:', error);
  }
}

export async function run() {
  await loadPositions();
  bindButtonActions();
  showRandomPosition();
}

const BOARD = new Chessboard(document.getElementById("board"), {
  position: FEN.start,
  assetsUrl: "./cm-chessboard-assets/"
});

let currentPositionIsMate;

// The player who has already moved is the
// one who does not have the move now.
function whoJustMoved(position) {
  var playerToMove = position.split(/ /)[1];
  if (playerToMove.substring(0, 1) === 'w') {
    return COLOR.black;
  }
  return COLOR.white;
}

// From https://stackoverflow.com/questions/879152/how-do-i-make-javascript-beep
var audioCtx = new (window.AudioContext || window.webkitAudioContext || window.audioContext);
function errorBeep() {
  var oscillator = audioCtx.createOscillator();
  var gainNode = audioCtx.createGain();
	var duration = 200; // milliseconds

	oscillator.connect(gainNode);
	gainNode.connect(audioCtx.destination);

	gainNode.gain.value = 0.25;
	oscillator.frequency.value = 440; // Hertz
	oscillator.type = 'sawtooth';

	oscillator.start();
	setTimeout(function() { oscillator.stop(); }, (duration ? duration : 500));
}

// just return true or false, randomly
function coinFlip() {
  return Math.floor(Math.random() * 2) === 1;
}

// choose a random position in the given array
function randomFrom(array) {
  var rand = Math.floor(Math.random() * array.length);
  return array[rand];
}

function randomMateOrNot() {
  const randomPair = randomFrom(POSITION_PAIRS);
  if (coinFlip()) {
    return { mate: true, position: randomPair.mate };
  } else {
    return { mate: false, position: randomPair.nonMate };
  }
}
function showSuccess() {
  const messageBox = document.getElementById("message");
  messageBox.classList.remove('error-message');
  messageBox.classList.add('success-message');
}
function showErrorMessage(message) {
  const messageBox = document.getElementById("message");
  messageBox.classList.remove('success-message');
  messageBox.classList.add('error-message');
  messageBox.textContent = message;
  errorBeep();
}
function resetMessage() {
  const messageBox = document.getElementById("message");
  messageBox.classList.remove("success-message");
  messageBox.classList.remove("error-message");
  messageBox.textContent = "";
}
function updateMateButtonAction() {
  document.getElementById("mate").addEventListener("click", function() {
    if (currentPositionIsMate) {
      showSuccess();
      showRandomPositionAfterDelay();
    } else {
      showErrorMessage('Not Mate!');
    }
  });
}
function updateNotMateButtonAction() {
  document.getElementById("not-mate").addEventListener("click", function() {
    if (currentPositionIsMate) {
      showErrorMessage('Mate!');
    } else {
      showSuccess();
      showRandomPositionAfterDelay();
    }
  });
}

function showRandomPosition() {
  var possibleMate = randomMateOrNot(),
      position = possibleMate.position;
  currentPositionIsMate = possibleMate.mate;
  resetMessage();
  BOARD.setOrientation(whoJustMoved(position) === COLOR.white ? COLOR.white : COLOR.black);
  BOARD.setPosition(position);
}
function showRandomPositionAfterDelay() {
  setTimeout(function() {
    showRandomPosition();
  }, 400);
}
function bindButtonActions() {
  updateMateButtonAction();
  updateNotMateButtonAction();
}
