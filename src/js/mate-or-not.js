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
        "8/1kp2RP1/8/3N4/8/2n5/r7/K7 w - - 0 1",
        "3R2k1/5ppp/r7/8/2b5/8/5PPP/6K1 b - - 1 1",
        "8/6kp/8/8/3b2pP/1P4n1/P5PR/4rQK1 w - - 0 1",
        "6q1/1p6/4pQ2/3pP3/6kp/8/1P5K/3B4 b - - 4 49", // Topalov Morozevich, 2012
        "8/1kp5/1p3P2/6P1/6Q1/2np4/2r4P/2K5 w - - 0 1",
        "7R/r5pk/6N1/5P2/8/p4P2/6K1/8 b - - 1 1",
        "4r2k/6p1/5p1p/1Q6/p2P1n2/N1R4P/6q1/7K w - - 0 1",
        "7k/7Q/p3q3/2p4p/Pp1n4/1P1B3P/2P5/7K b - - 9 47", // Can Ererdem, 2012
        "6k1/R5pp/4Np2/5P2/2n5/8/P1P5/2K3r1 w - - 0 1",
        "k7/p1N3b1/5q2/8/8/2P5/P1K5/1R6 b - - 1 1",
        "3r3k/8/7p/8/4P1P1/5r2/q1K1Qb1R/2R5 w - - 0 39", // Caro Naroditsky 2012
        "4Q3/4q1kp/2p2p1P/1p1n4/3P4/6P1/3B1P1K/8 b - - 0 44", // Carlsen Jobava 2017
        "6k1/5pb1/6p1/6N1/8/8/PR6/K3r3 w - - 0 1",
        "2R5/4bR1k/1p1p3p/7P/4P3/5P2/r4q1P/7K b - - 0 51", // Carlsen Karjakin NY 2016
        "1Q6/8/8/q7/8/K7/2k5/8 w - - 1 78", // Marjusaari AhvenJarvi 2012
        "5Q2/6p1/p4kp1/1p1B4/5P2/P3P2P/3n2PK/4q3 b - - 2 36", // Ehlvest Valli 2012
      ],
      NON_MATE_POSTIONS = [
        "3Rk3/2q5/8/8/7B/6P1/6K1/8 b - - 0 1",
        "7R/2k5/r1p5/8/8/1P6/K1Pn4/8 w - - 0 1",
        "5bkQ/ppq2n1p/2p5/8/8/1P4P1/PB3PKP/8 b - - 1 1",
        "6kR/4K1P1/8/8/8/8/5p2/3r4 b - - 1 1",
        "8/2kp1RP1/8/3B4/8/2n5/r7/K7 w - - 0 1",
        "3R2k1/5ppp/r7/2b5/8/8/5PPP/6K1 b - - 1 1",
        "8/6kp/8/8/3b2pP/1P4n1/P5PR/5QK1 w - - 0 1",
        "6q1/1p6/4p2Q/3pP3/6kp/8/1P5K/3B4 b - - 4 49",
        "8/1k6/1pp2P2/6P1/8/2np4/2r3QP/2K5 w - - 0 1",
        "r6R/6pk/6N1/5P2/8/p4P2/6K1/8 b - - 1 1",
        "4r2k/6p1/5p1p/1Q6/p2P1n2/2R1N2P/6q1/7K w - - 0 1",
        "7k/7Q/p3q3/2p2n1p/Pp6/1P1B3P/2P5/7K b - - 9 47",
        "6k1/R5pp/4Np2/5P2/8/2n5/P1P5/2K3r1 w - - 0 1",
        "1k6/1p1N2b1/5q2/8/8/1P1P4/3K4/2R5 b - - 1 1",
        "3r3k/8/7p/8/6P1/4Pr2/q1K1Qb1R/2R5 w - - 0 39",
        "4Q3/4q1kp/2p4P/1p1n1p2/3P4/6P1/3B1P1K/8 b - - 0 44",
        "6k1/5p2/4b1p1/6N1/8/8/PR6/K3r3 w - - 0 1",
        "2R5/4bR1k/1p1p3p/6qP/4P3/5P2/r6P/7K b - - 0 51",
        "1Q6/8/q7/8/K7/8/2k5/8 w - - 1 78",
        "5Q2/6p1/p4kp1/1pB5/5P2/P3P2P/3n2PK/4q3 b - - 2 36",
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
    if (coinFlip()) {
      return {mate: true, position: randomFrom(MATE_POSTIONS)};
    } else {
      return {mate: false, position: randomFrom(NON_MATE_POSTIONS)};
    }
  }
  function showSuccess() {
    var messageBox = $("#message");
    messageBox.removeClass('error-message');
    messageBox.addClass('success-message');
  }
  function showErrorMessage(message) {
    var messageBox = $("#message");
    messageBox.removeClass('success-message');
    messageBox.addClass('error-message');
    messageBox.text(message);
    errorBeep();
  }
  function resetMessage() {
    var messageBox = $("#message").text("");
    messageBox.removeClass("success-message");
    messageBox.removeClass("error-message");
    messageBox.text("");
  }
  function updateMateButtonAction() {
    $("#mate").click(function() {
      if (currentPositionIsMate) {
        showSuccess();
        showRandomPositionAfterDelay();
      } else {
        showErrorMessage('Not Mate!');
      }
    });
  }
  function updateNotMateButtonAction() {
    $("#not-mate").click(function() {
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
      BOARD.orientation(whoJustMoved(position));
      BOARD.position(position);
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

  window.mornot = {
    run: function() {
      bindButtonActions();
      showRandomPosition();
    }
  };
})();
