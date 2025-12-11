const canvas = document.getElementById('board');
const ctx = canvas.getContext('2d');
const nextCanvas = document.getElementById('next');
const nextCtx = nextCanvas.getContext('2d');

const scoreEl = document.getElementById('score');
const levelEl = document.getElementById('level');
const linesEl = document.getElementById('lines');
const resetBtn = document.getElementById('resetBtn');
const pauseBtn = document.getElementById('pauseBtn');

const ROWS = 20;
const COLS = 10;
const BLOCK = canvas.width / COLS;
const COLORS = [
    '#06b6d4', // I
    '#f59e0b', // L
    '#7c3aed', // J
    '#22c55e', // S
    '#ef4444', // Z
    '#e5e7eb', // O
    '#a855f7', // T
];

const SHAPES = [
    [
        [1, 1, 1, 1],
    ],
    [
        [2, 0, 0],
        [2, 2, 2],
    ],
    [
        [0, 0, 3],
        [3, 3, 3],
    ],
    [
        [0, 4, 4],
        [4, 4, 0],
    ],
    [
        [5, 5, 0],
        [0, 5, 5],
    ],
    [
        [6, 6],
        [6, 6],
    ],
    [
        [0, 7, 0],
        [7, 7, 7],
    ],
];

let board = createBoard();
let current = randomPiece();
let nextPiece = randomPiece();
let dropCounter = 0;
let lastTime = 0;
let score = 0;
let level = 1;
let lines = 0;
let dropInterval = 800;
let paused = false;
let gameOver = false;

function createBoard() {
    return Array.from({ length: ROWS }, () => Array(COLS).fill(0));
}

function drawMatrix(matrix, offset, context, blockSize = BLOCK) {
    matrix.forEach((row, y) => {
        row.forEach((value, x) => {
            if (value !== 0) {
                const color = COLORS[value - 1];
                context.fillStyle = color;
                context.shadowColor = color + 'aa';
                context.shadowBlur = 12;
                context.fillRect((x + offset.x) * blockSize, (y + offset.y) * blockSize, blockSize - 1, blockSize - 1);
            }
        });
    });
}

function draw() {
    ctx.fillStyle = 'rgba(17, 24, 39, 0.95)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    drawMatrix(board, { x: 0, y: 0 }, ctx);
    drawMatrix(current.matrix, current.pos, ctx);
}

function drawNext() {
    nextCtx.clearRect(0, 0, nextCanvas.width, nextCanvas.height);
    const size = 24;
    drawMatrix(nextPiece.matrix, { x: 1, y: 1 }, nextCtx, size);
}

function merge(board, piece) {
    piece.matrix.forEach((row, y) => {
        row.forEach((value, x) => {
            if (value !== 0) {
                board[y + piece.pos.y][x + piece.pos.x] = value;
            }
        });
    });
}

function collide(board, piece) {
    for (let y = 0; y < piece.matrix.length; y++) {
        for (let x = 0; x < piece.matrix[y].length; x++) {
            if (
                piece.matrix[y][x] !== 0 &&
                (board[y + piece.pos.y] && board[y + piece.pos.y][x + piece.pos.x]) !== 0
            ) {
                return true;
            }
        }
    }
    return false;
}

function rotate(matrix) {
    return matrix[0].map((_, i) => matrix.map(row => row[i]).reverse());
}

function playerRotate() {
    const rotated = rotate(current.matrix);
    const pos = current.pos.x;
    let offset = 1;
    current.matrix = rotated;
    while (collide(board, current)) {
        current.pos.x += offset;
        offset = -(offset + (offset > 0 ? 1 : -1));
        if (offset > current.matrix[0].length) {
            current.matrix = rotate(rotate(rotate(current.matrix)));
            current.pos.x = pos;
            return;
        }
    }
}

function sweep() {
    let rowsCleared = 0;
    outer: for (let y = board.length - 1; y >= 0; --y) {
        if (board[y].every(value => value !== 0)) {
            const row = board.splice(y, 1)[0].fill(0);
            board.unshift(row);
            ++rowsCleared;
            ++y;
        }
    }
    if (rowsCleared > 0) {
        const points = [0, 40, 100, 300, 1200];
        score += points[rowsCleared] * level;
        lines += rowsCleared;
        if (lines % 10 === 0) {
            level++;
            dropInterval = Math.max(120, dropInterval - 80);
        }
        updatePanel();
    }
}

function updatePanel() {
    scoreEl.textContent = score;
    levelEl.textContent = level;
    linesEl.textContent = lines;
}

function drop() {
    current.pos.y++;
    if (collide(board, current)) {
        current.pos.y--;
        merge(board, current);
        sweep();
        spawn();
    }
    dropCounter = 0;
}

function spawn() {
    current = nextPiece;
    current.pos = { x: (COLS / 2 | 0) - (current.matrix[0].length / 2 | 0), y: 0 };
    nextPiece = randomPiece();
    drawNext();
    if (collide(board, current)) {
        gameOver = true;
        pauseBtn.textContent = 'Game Over';
    }
}

function randomPiece() {
    const index = Math.floor(Math.random() * SHAPES.length);
    const matrix = SHAPES[index].map(row => [...row]);
    return {
        matrix,
        pos: { x: (COLS / 2 | 0) - (matrix[0].length / 2 | 0), y: 0 },
    };
}

function update(time = 0) {
    const delta = time - lastTime;
    lastTime = time;

    if (!paused && !gameOver) {
        dropCounter += delta;
        if (dropCounter > dropInterval) {
            drop();
        }
        draw();
    }
    requestAnimationFrame(update);
}

function resetGame() {
    board = createBoard();
    current = randomPiece();
    nextPiece = randomPiece();
    dropInterval = 800;
    score = 0;
    level = 1;
    lines = 0;
    paused = false;
    gameOver = false;
    pauseBtn.textContent = '⏯ Pause';
    updatePanel();
    drawNext();
}

function hardDrop() {
    while (!collide(board, current)) {
        current.pos.y++;
    }
    current.pos.y--;
    merge(board, current);
    sweep();
    spawn();
}

document.addEventListener('keydown', event => {
    if (gameOver) return;
    if (event.code === 'ArrowLeft') {
        current.pos.x--;
        if (collide(board, current)) current.pos.x++;
    } else if (event.code === 'ArrowRight') {
        current.pos.x++;
        if (collide(board, current)) current.pos.x--;
    } else if (event.code === 'ArrowDown') {
        drop();
    } else if (event.code === 'Space') {
        hardDrop();
    } else if (event.code === 'KeyR' || event.code === 'ArrowUp') {
        playerRotate();
    } else if (event.code === 'KeyP') {
        togglePause();
    }
});

resetBtn.addEventListener('click', () => {
    resetGame();
});

pauseBtn.addEventListener('click', () => {
    togglePause();
});

function togglePause() {
    if (gameOver) return;
    paused = !paused;
    pauseBtn.textContent = paused ? 'Fortsetzen' : '⏯ Pause';
}

updatePanel();
resetGame();
update();
