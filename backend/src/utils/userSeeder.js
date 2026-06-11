const db = require('../db');

const defaultBooks = {
  'Fiction': [
    { title: 'The Kite Runner', author: 'Khaled Hosseini', year: 2003, pages: 371 },
    { title: 'To Kill a Mockingbird', author: 'Harper Lee', year: 1960, pages: 281 },
    { title: 'The Alchemist', author: 'Paulo Coelho', year: 1988, pages: 197 },
    { title: 'The Great Gatsby', author: 'F. Scott Fitzgerald', year: 1925, pages: 180 },
    { title: 'The Midnight Library', author: 'Matt Haig', year: 2020, pages: 288 },
    { title: 'Normal People', author: 'Sally Rooney', year: 2018, pages: 273 }
  ],
  'Non-Fiction': [
    { title: 'Sapiens: A Brief History of Humankind', author: 'Yuval Noah Harari', year: 2011, pages: 443 },
    { title: 'Educated', author: 'Tara Westover', year: 2018, pages: 352 },
    { title: 'The Emperor of All Maladies', author: 'Siddhartha Mukherjee', year: 2010, pages: 571 },
    { title: 'The Tipping Point', author: 'Malcolm Gladwell', year: 2000, pages: 304 },
    { title: 'Born a Crime', author: 'Trevor Noah', year: 2016, pages: 304 },
    { title: 'Quiet: The Power of Introverts', author: 'Susan Cain', year: 2012, pages: 368 }
  ],
  'Science Fiction': [
    { title: 'Dune', author: 'Frank Herbert', year: 1965, pages: 688 },
    { title: 'Foundation', author: 'Isaac Asimov', year: 1951, pages: 255 },
    { title: "Ender's Game", author: 'Orson Scott Card', year: 1985, pages: 324 },
    { title: 'Project Hail Mary', author: 'Andy Weir', year: 2021, pages: 476 },
    { title: 'Neuromancer', author: 'William Gibson', year: 1984, pages: 271 },
    { title: 'The Martian', author: 'Andy Weir', year: 2011, pages: 369 }
  ],
  'Fantasy': [
    { title: "Harry Potter and the Sorcerer's Stone", author: 'J.K. Rowling', year: 1997, pages: 309 },
    { title: 'The Hobbit', author: 'J.R.R. Tolkien', year: 1937, pages: 310 },
    { title: 'The Name of the Wind', author: 'Patrick Rothfuss', year: 2007, pages: 662 },
    { title: 'A Game of Thrones', author: 'George R.R. Martin', year: 1996, pages: 694 },
    { title: 'The Way of Kings', author: 'Brandon Sanderson', year: 2010, pages: 1007 },
    { title: 'Percy Jackson & the Olympians', author: 'Rick Riordan', year: 2005, pages: 377 }
  ],
  'Mystery': [
    { title: 'The Girl with the Dragon Tattoo', author: 'Stieg Larsson', year: 2005, pages: 465 },
    { title: 'Gone Girl', author: 'Gillian Flynn', year: 2012, pages: 415 },
    { title: 'And Then There Were None', author: 'Agatha Christie', year: 1939, pages: 272 },
    { title: 'The Da Vinci Code', author: 'Dan Brown', year: 2003, pages: 454 },
    { title: 'Big Little Lies', author: 'Liane Moriarty', year: 2014, pages: 460 },
    { title: 'The Silent Patient', author: 'Alex Michaelides', year: 2019, pages: 336 }
  ],
  'Thriller': [
    { title: 'The Silence of the Lambs', author: 'Thomas Harris', year: 1988, pages: 338 },
    { title: 'The Bourne Identity', author: 'Robert Ludlum', year: 1980, pages: 543 },
    { title: 'Shutter Island', author: 'Dennis Lehane', year: 2003, pages: 369 },
    { title: 'The Reversal', author: 'Michael Connelly', year: 2010, pages: 400 },
    { title: 'Jack Reacher: Killing Floor', author: 'Lee Child', year: 1997, pages: 528 },
    { title: 'Angels & Demons', author: 'Dan Brown', year: 2000, pages: 569 }
  ],
  'Romance': [
    { title: 'Pride and Prejudice', author: 'Jane Austen', year: 1813, pages: 279 },
    { title: 'The Fault in Our Stars', author: 'John Green', year: 2012, pages: 313 },
    { title: 'The Notebook', author: 'Nicholas Sparks', year: 1996, pages: 214 },
    { title: 'Me Before You', author: 'Jojo Moyes', year: 2012, pages: 369 },
    { title: 'Red, White & Royal Blue', author: 'Casey McQuiston', year: 2019, pages: 418 },
    { title: 'It Ends with Us', author: 'Colleen Hoover', year: 2016, pages: 384 }
  ],
  'Horror': [
    { title: 'The Shining', author: 'Stephen King', year: 1977, pages: 447 },
    { title: 'Dracula', author: 'Bram Stoker', year: 1897, pages: 418 },
    { title: 'Frankenstein', author: 'Mary Shelley', year: 1818, pages: 280 },
    { title: 'It', author: 'Stephen King', year: 1986, pages: 1138 },
    { title: 'Bird Box', author: 'Josh Malerman', year: 2014, pages: 262 },
    { title: 'The Haunting of Hill House', author: 'Shirley Jackson', year: 1959, pages: 182 }
  ],
  'Biography': [
    { title: 'Steve Jobs', author: 'Walter Isaacson', year: 2011, pages: 656 },
    { title: 'Becoming', author: 'Michelle Obama', year: 2018, pages: 448 },
    { title: 'Elon Musk', author: 'Walter Isaacson', year: 2023, pages: 688 },
    { title: 'The Diary of a Young Girl', author: 'Anne Frank', year: 1947, pages: 283 },
    { title: 'Shoe Dog', author: 'Phil Knight', year: 2016, pages: 399 },
    { title: 'Long Walk to Freedom', author: 'Nelson Mandela', year: 1994, pages: 630 }
  ],
  'History': [
    { title: 'The Silk Roads', author: 'Peter Frankopan', year: 2015, pages: 656 },
    { title: 'SPQR: A History of Ancient Rome', author: 'Mary Beard', year: 2015, pages: 608 },
    { title: 'Chernobyl: History of a Tragedy', author: 'Serhii Plokhy', year: 2018, pages: 432 },
    { title: "A People's History of the United States", author: 'Howard Zinn', year: 1980, pages: 729 },
    { title: 'Guns, Germs, and Steel', author: 'Jared Diamond', year: 1997, pages: 425 },
    { title: 'The Rise and Fall of the Third Reich', author: 'William L. Shirer', year: 1960, pages: 1245 }
  ],
  'Self Help': [
    { title: 'Atomic Habits', author: 'James Clear', year: 2018, pages: 320 },
    { title: 'The Power of Now', author: 'Eckhart Tolle', year: 1997, pages: 236 },
    { title: 'The 7 Habits of Highly Effective People', author: 'Stephen R. Covey', year: 1989, pages: 381 },
    { title: 'How to Win Friends and Influence People', author: 'Dale Carnegie', year: 1936, pages: 291 },
    { title: 'The Subtle Art of Not Giving a F*ck', author: 'Mark Manson', year: 2016, pages: 224 },
    { title: 'Think and Grow Rich', author: 'Napoleon Hill', year: 1937, pages: 238 }
  ],
  'Psychology': [
    { title: 'Thinking, Fast and Slow', author: 'Daniel Kahneman', year: 2011, pages: 499 },
    { title: 'Influence: The Psychology of Persuasion', author: 'Robert B. Cialdini', year: 1984, pages: 320 },
    { title: "Man's Search for Meaning", author: 'Viktor E. Frankl', year: 1946, pages: 165 },
    { title: 'Grit: The Power of Passion and Perseverance', author: 'Angela Duckworth', year: 2016, pages: 352 },
    { title: 'Mindset: The New Psychology of Success', author: 'Carol S. Dweck', year: 2006, pages: 320 },
    { title: 'Flow: The Psychology of Optimal Experience', author: 'Mihaly Csikszentmihalyi', year: 1990, pages: 303 }
  ],
  'Technology': [
    { title: 'Designing Data-Intensive Applications', author: 'Martin Kleppmann', year: 2017, pages: 616 },
    { title: 'The Phoenix Project', author: 'Gene Kim', year: 2013, pages: 384 },
    { title: 'Life 3.0', author: 'Max Tegmark', year: 2017, pages: 384 },
    { title: 'The Innovators', author: 'Walter Isaacson', year: 2014, pages: 544 },
    { title: 'Superintelligence', author: 'Nick Bostrom', year: 2014, pages: 390 },
    { title: 'Gödel, Escher, Bach', author: 'Douglas R. Hofstadter', year: 1979, pages: 777 }
  ],
  'Programming': [
    { title: 'Clean Code', author: 'Robert C. Martin', year: 2008, pages: 464 },
    { title: 'Refactoring', author: 'Martin Fowler', year: 1999, pages: 448 },
    { title: 'Design Patterns', author: 'Erich Gamma', year: 1994, pages: 395 },
    { title: 'The Pragmatic Programmer', author: 'David Thomas', year: 1999, pages: 352 },
    { title: 'Code Complete', author: 'Steve McConnell', year: 1993, pages: 960 },
    { title: 'Introduction to Algorithms', author: 'Thomas H. Cormen', year: 1990, pages: 1292 }
  ],
  'Business': [
    { title: 'Zero to One', author: 'Peter Thiel', year: 2014, pages: 224 },
    { title: 'The Lean Startup', author: 'Eric Ries', year: 2011, pages: 336 },
    { title: 'Good to Great', author: 'Jim Collins', year: 2001, pages: 320 },
    { title: 'The Intelligent Investor', author: 'Benjamin Graham', year: 1949, pages: 640 },
    { title: 'The Hard Thing About Hard Things', author: 'Ben Horowitz', year: 2014, pages: 304 },
    { title: 'Blue Ocean Strategy', author: 'W. Chan Kim', year: 2005, pages: 272 }
  ]
};

async function seedUserBooks(userId) {
  let count = 0;
  for (const [genre, books] of Object.entries(defaultBooks)) {
    for (let index = 0; index < books.length; index++) {
      const book = books[index];
      
      let shelf = 'Want To Read';
      let currentPage = 0;
      let completionDate = null;
      let rating = null;
      let review = null;

      // Distribute shelf statuses realistically
      if (index === 0 || index === 3) {
        shelf = 'Finished Reading';
        currentPage = book.pages;
        completionDate = new Date(Date.now() - (index + 1) * 5 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
        rating = 4 + (index % 2); // 4 or 5 stars
        review = `An exceptional and deeply insightful book. Highly recommended for anyone interested in ${genre.toLowerCase()}!`;
      } else if (index === 1 || index === 4) {
        shelf = 'Currently Reading';
        currentPage = Math.floor(book.pages * 0.45);
      } else {
        shelf = 'Want To Read';
        currentPage = 0;
      }

      await db.query(
        `INSERT INTO books
           (user_id, title, author, genre, publication_year,
            shelf, current_page, total_pages,
            completion_date, rating, review)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)`,
        [
          userId,
          book.title,
          book.author || 'Unknown',
          genre,
          book.year,
          shelf,
          currentPage,
          book.pages,
          completionDate,
          rating,
          review
        ]
      );
      count++;
    }
  }
  return count;
}

module.exports = { seedUserBooks };
