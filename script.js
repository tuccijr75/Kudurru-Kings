// script.js
document.addEventListener('DOMContentLoaded', () => {
    const player1Hand = document.getElementById('player1-hand');
    const player2Hand = document.getElementById('player2-hand');
    const courtCards = document.getElementById('court-cards');
    const drawCardButton = document.getElementById('draw-card');
    const endTurnButton = document.getElementById('end-turn');

    // Sample card data
    const cards = [
        { id: 1, name: 'Adamu Warrior', type: 'Character', faction: 'Adamu' },
        { id: 2, name: 'Anunnaki Priest', type: 'Character', faction: 'Anunnaki' },
        { id: 3, name: 'Relic Engine', type: 'Relic', effect: 'Reroll Test modifier' },
        { id: 4, name: 'Name of Justice', type: 'Name', effect: 'Rewrite local rules' },
        { id: 5, name: 'Warden of the Threshold', type: 'Boss', faction: 'Anunnaki' },
        { id: 6, name: 'Pet Lion', type: 'Pet', effect: 'Supports Character' }
    ];

    // Initialize players' hands
    let player1Cards = [cards[0], cards[2], cards[4]];
    let player2Cards = [cards[1], cards[3], cards[5]];

    // Render player hands
    function renderHands() {
        player1Hand.innerHTML = '';
        player2Hand.innerHTML = '';

        player1Cards.forEach(card => {
            const cardElement = document.createElement('div');
            cardElement.className = 'card';
            cardElement.innerHTML = `<h3>${card.name}</h3><p>${card.type}</p>`;
            player1Hand.appendChild(cardElement);
        });

        player2Cards.forEach(card => {
            const cardElement = document.createElement('div');
            cardElement.className = 'card';
            cardElement.innerHTML = `<h3>${card.name}</h3><p>${card.type}</p>`;
            player2Hand.appendChild(cardElement);
        });
    }

    // Draw a card
    drawCardButton.addEventListener('click', () => {
        if (player1Cards.length < 5) {
            const randomCard = cards[Math.floor(Math.random() * cards.length)];
            player1Cards.push(randomCard);
            renderHands();
        }
    });

    // End turn
    endTurnButton.addEventListener('click', () => {
        alert('Turn ended');
    });

    // Initial render
    renderHands();
});
