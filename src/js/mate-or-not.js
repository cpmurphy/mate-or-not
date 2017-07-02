/*
 * Copyright 2017 Christian Murphy
 * Released under the MIT license
 */

;(function () {
  'use strict';

  // Globals for this module

  var MATE_POSTIONS = [
        "3Rk3/5q2/8/8/7B/6P1/6K1/8 b - - 0 1",
        "7R/2k5/r1p5/8/8/8/KPPn4/8 w - - 0 1",
        "5bkQ/ppq2p1p/2p5/8/8/1P4P1/PB3PKP/8 b - - 1 1",
        "6kR/6P1/5K2/8/8/8/5p2/3r4 b - - 1 1",
        "8/1kp2RP1/8/3N4/8/2n5/r7/K7 w - - 1 1",
        "3R2k1/5ppp/r7/8/2b5/8/5PPP/6K1 b - - 1 1",
        "8/6kp/8/8/3b2pP/1P4n1/P5PR/4rQK1 w - - 1 1",
      ],
      NON_MATE_POSTIONS = [
        "3Rk3/2q5/8/8/7B/6P1/6K1/8 b - - 0 1",
        "7R/2k5/r1p5/8/8/1P6/K1Pn4/8 w - - 0 1",
        "5bkQ/ppq2n1p/2p5/8/8/1P4P1/PB3PKP/8 b - - 1 1",
        "6kR/4K1P1/8/8/8/8/5p2/3r4 b - - 1 1",
        "8/2kp1RP1/8/3B4/8/2n5/r7/K7 w - - 1 1",
        "3R2k1/5ppp/r7/2b5/8/8/5PPP/6K1 b - - 1 1",
        "8/6kp/8/8/3b2pP/1P4n1/P5PR/5QK1 w - - 1 1",
      ];

  var BOARD = new ChessBoard('board');
  var currentPositionIsMate;  // global AND mutable!!!


  // The player who has already moved is the
  // one who does not have the move now.
  function whoJustMoved(position) {
    var playerToMove = position.split(/ /)[1];
    if (playerToMove.substring(0, 1) === 'w') {
      return 'black';
    }
    return 'white';
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
		setTimeout(function(){oscillator.stop()}, (duration ? duration : 500));
	};

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
    if (coinFlip()) {
      return {mate: true, position: randomFrom(MATE_POSTIONS)};
    } else {
      return {mate: false, position: randomFrom(NON_MATE_POSTIONS)};
    }
  }
  function showGreenSuccess() {
    var messageBox = $("#message");
    messageBox.removeClass('error-message');
    messageBox.addClass('success-message');
  }
  function showErrorMessage(message) {
    var messageBox = $("#message");
    messageBox.removeClass('success-message');
    messageBox.addClass('error-message');
    messageBox.text(message);
  }
  function removeErrorMessage() {
    $("#message").text("");
  }
  function updateMateButtonAction() {
    $("#mate").click(function() {
      if (currentPositionIsMate) {
        showGreenSuccess();
        showRandomPosition();
      } else {
				errorBeep();
        showErrorMessage('Not Mate!');
      }
    });
  }
  function updateNotMateButtonAction() {
    $("#not-mate").click(function() {
      if (currentPositionIsMate) {
				errorBeep();
        showErrorMessage('Mate!');
      } else {
        showGreenSuccess();
        showRandomPosition();
      }
    });
  }

  function showRandomPosition() {
      var possibleMate = randomMateOrNot(),
          position = possibleMate.position;
      currentPositionIsMate = possibleMate.mate;
      removeErrorMessage();
      BOARD.orientation(whoJustMoved(position));
      BOARD.position(position);
  }
  function bindButtonActions() {
    updateMateButtonAction();
    updateNotMateButtonAction();
  }

  window.mornot = {
    run: function() {
      bindButtonActions();
      showRandomPosition();
    }
  };
})();
