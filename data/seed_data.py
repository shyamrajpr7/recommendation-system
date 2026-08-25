"""Seed data for the CineRead cinema ticketing system.

Defines theaters, screens, showtimes, and the movie/book catalog used to
populate the SQLite database on application startup.
"""

# ---------------------------------------------------------------------------
# Cinema ticketing seed data
# ---------------------------------------------------------------------------

THEATERS = [
    {"name": "Grand Cineplex", "city": "Koramangala"},
    {"name": "Starlight Cinemas", "city": "Indiranagar"},
    {"name": "ScreenWorld", "city": "MG Road"},
]

# (theater_name, screen_name, rows, cols, base_price_inr)
SCREENS = [
    ("Grand Cineplex", "Screen 1", 6, 8, 200),
    ("Grand Cineplex", "Screen 2", 8, 10, 250),
    ("Grand Cineplex", "Screen 3", 5, 7, 180),
    ("Starlight Cinemas", "IMAX 1", 8, 12, 350),
    ("Starlight Cinemas", "Screen 2", 6, 8, 220),
    ("ScreenWorld", "Screen 1", 7, 9, 240),
    ("ScreenWorld", "Screen 2", 5, 6, 160),
]

SHOW_TIMES = ["10:30", "13:15", "16:00", "19:30", "22:00"]
SHOWTIME_DAYS_AHEAD = 4

# Movies with showtimes scheduled (subset of the catalog that is "now showing")
NOW_SHOWING = [
    "Inception",
    "Interstellar",
    "The Dark Knight",
    "Dune: Part Two",
    "Oppenheimer",
    "Everything Everywhere All at Once",
    "Spider-Man: Into the Spider-Verse",
    "Parasite",
    "The Matrix",
    "Blade Runner 2049",
]

SEED_ITEMS = [
    # Movies
    {
        "title": "Inception",
        "item_type": "Movie",
        "genre": "Sci-Fi",
        "rating": 8.8,
        "synopsis": "A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.",
        "creator": "Christopher Nolan",
        "year": 2010
    },
    {
        "title": "Interstellar",
        "item_type": "Movie",
        "genre": "Sci-Fi",
        "rating": 8.7,
        "synopsis": "When Earth becomes uninhabitable in the future, a farmer and ex-NASA pilot, Joseph Cooper, is tasked to pilot a spacecraft, along with a team of researchers, to find a new planet for humans.",
        "creator": "Christopher Nolan",
        "year": 2014
    },
    {
        "title": "The Matrix",
        "item_type": "Movie",
        "genre": "Sci-Fi",
        "rating": 8.7,
        "synopsis": "When a beautiful stranger leads computer hacker Neo to a forbidding underworld, he discovers the shocking truth--the life he knows is the elaborate deception of an evil cyber-intelligence.",
        "creator": "The Wachowskis",
        "year": 1999
    },
    {
        "title": "Blade Runner 2049",
        "item_type": "Movie",
        "genre": "Sci-Fi",
        "rating": 8.0,
        "synopsis": "Young Blade Runner K's discovery of a long-buried secret leads him to track down former Blade Runner Rick Deckard, who's been missing for thirty years.",
        "creator": "Denis Villeneuve",
        "year": 2017
    },
    {
        "title": "The Dark Knight",
        "item_type": "Movie",
        "genre": "Action",
        "rating": 9.0,
        "synopsis": "When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests of his ability to fight injustice.",
        "creator": "Christopher Nolan",
        "year": 2008
    },
    {
        "title": "Pulp Fiction",
        "item_type": "Movie",
        "genre": "Crime",
        "rating": 8.9,
        "synopsis": "The lives of two mob hitmen, a boxer, a gangster and his wife, and a pair of diner bandits intertwine in four tales of violence and redemption.",
        "creator": "Quentin Tarantino",
        "year": 1994
    },
    {
        "title": "Parasite",
        "item_type": "Movie",
        "genre": "Thriller",
        "rating": 8.5,
        "synopsis": "Greed and class discrimination threaten the newly formed symbiotic relationship between the wealthy Park family and the destitute Kim clan.",
        "creator": "Bong Joon Ho",
        "year": 2019
    },
    {
        "title": "Spirited Away",
        "item_type": "Movie",
        "genre": "Animation",
        "rating": 8.6,
        "synopsis": "During her family's move to the suburbs, a sullen 10-year-old girl wanders into a world ruled by gods, witches, and spirits, and where humans are changed into beasts.",
        "creator": "Hayao Miyazaki",
        "year": 2001
    },
    {
        "title": "Whiplash",
        "item_type": "Movie",
        "genre": "Drama",
        "rating": 8.5,
        "synopsis": "A promising young drummer enlists at a cut-throat music conservatory where his dreams of greatness are mentored by an instructor who will stop at nothing to realize a student's potential.",
        "creator": "Damien Chazelle",
        "year": 2014
    },
    {
        "title": "The Grand Budapest Hotel",
        "item_type": "Movie",
        "genre": "Comedy",
        "rating": 8.1,
        "synopsis": "A writer encounters the owner of a high-class European hotel who tells of his early years as a lobby boy in the hotel's glorious years under an exceptional concierge.",
        "creator": "Wes Anderson",
        "year": 2014
    },
    {
        "title": "Dune: Part Two",
        "item_type": "Movie",
        "genre": "Sci-Fi",
        "rating": 8.6,
        "synopsis": "Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family in a vast desert planet conflict.",
        "creator": "Denis Villeneuve",
        "year": 2024
    },
    {
        "title": "Everything Everywhere All at Once",
        "item_type": "Movie",
        "genre": "Sci-Fi",
        "rating": 7.8,
        "synopsis": "A middle-aged Chinese immigrant is swept up into an insane adventure in which she alone can save existence by exploring other universes and connecting with the lives she could have led.",
        "creator": "Daniel Kwan, Daniel Scheinert",
        "year": 2022
    },
    {
        "title": "Se7en",
        "item_type": "Movie",
        "genre": "Mystery",
        "rating": 8.6,
        "synopsis": "Two detectives, a rookie and a veteran, hunt a serial killer who uses the seven deadly sins as his motives in a dark, rain-soaked city.",
        "creator": "David Fincher",
        "year": 1995
    },
    {
        "title": "Alien",
        "item_type": "Movie",
        "genre": "Horror",
        "rating": 8.5,
        "synopsis": "The crew of a commercial spacecraft encounters a deadly lifeform after investigating an unknown transmission on a remote moon.",
        "creator": "Ridley Scott",
        "year": 1979
    },
    {
        "title": "The Silence of the Lambs",
        "item_type": "Movie",
        "genre": "Thriller",
        "rating": 8.6,
        "synopsis": "A young F.B.I. cadet must receive the help of an incarcerated and manipulative cannibal killer to help catch another serial killer.",
        "creator": "Jonathan Demme",
        "year": 1991
    },
    {
        "title": "Amélie",
        "item_type": "Movie",
        "genre": "Romance",
        "rating": 8.3,
        "synopsis": "Amélie is an innocent and naive girl in Paris with her own sense of justice. She decides to help those around her and, along the way, discovers love.",
        "creator": "Jean-Pierre Jeunet",
        "year": 2001
    },
    {
        "title": "Oppenheimer",
        "item_type": "Movie",
        "genre": "Drama",
        "rating": 8.9,
        "synopsis": "The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb during World War II.",
        "creator": "Christopher Nolan",
        "year": 2023
    },
    {
        "title": "Spider-Man: Into the Spider-Verse",
        "item_type": "Movie",
        "genre": "Animation",
        "rating": 8.4,
        "synopsis": "Teen Miles Morales becomes the Spider-Man of his universe and must join with five spider-powered individuals from other dimensions to stop a threat for all realities.",
        "creator": "Bob Persichetti, Peter Ramsey",
        "year": 2018
    },
    # Books
    {
        "title": "Dune",
        "item_type": "Book",
        "genre": "Sci-Fi",
        "rating": 8.7,
        "synopsis": "Set on the desert planet Arrakis, Dune is the story of Paul Atreides, heir to a noble family in a complex intergalactic empire control of the spice melange.",
        "creator": "Frank Herbert",
        "year": 1965
    },
    {
        "title": "Neuromancer",
        "item_type": "Book",
        "genre": "Sci-Fi",
        "rating": 8.2,
        "synopsis": "Case was the sharpest data-thief in the matrix until he crossed the wrong people. Now a mysterious employer offers him a second chance in cyberspace.",
        "creator": "William Gibson",
        "year": 1984
    },
    {
        "title": "The Three-Body Problem",
        "item_type": "Book",
        "genre": "Sci-Fi",
        "rating": 8.4,
        "synopsis": "Set against the backdrop of China's Cultural Revolution, a secret military project sends signals into space to establish contact with aliens on the brink of extinction.",
        "creator": "Cixin Liu",
        "year": 2008
    },
    {
        "title": "Project Hail Mary",
        "item_type": "Book",
        "genre": "Sci-Fi",
        "rating": 8.8,
        "synopsis": "Ryland Grace is the sole survivor on a desperate, last-chance mission to save humanity from an extinction-level solar crisis.",
        "creator": "Andy Weir",
        "year": 2021
    },
    {
        "title": "The Hobbit",
        "item_type": "Book",
        "genre": "Fantasy",
        "rating": 8.9,
        "synopsis": "Bilbo Baggins is a hobbit who enjoys a comfortable, unambitious life, until wizard Gandalf and thirteen dwarves invite him on a quest to reclaim stolen dragon treasure.",
        "creator": "J.R.R. Tolkien",
        "year": 1937
    },
    {
        "title": "The Name of the Wind",
        "item_type": "Book",
        "genre": "Fantasy",
        "rating": 8.6,
        "synopsis": "The story of Kvothe, an orphan who grows up to become a legendary wizard, musician, and infamous figure in a richly detailed magical realm.",
        "creator": "Patrick Rothfuss",
        "year": 2007
    },
    {
        "title": "1984",
        "item_type": "Book",
        "genre": "Dystopian",
        "rating": 8.7,
        "synopsis": "Winston Smith wrestles with oppressive totalitarian censorship and omnipresent government surveillance in a nightmarish future society ruled by Big Brother.",
        "creator": "George Orwell",
        "year": 1949
    },
    {
        "title": "The Silent Patient",
        "item_type": "Book",
        "genre": "Thriller",
        "rating": 8.1,
        "synopsis": "Alicia Berenson's life is seemingly perfect. Then one evening she shoots her husband five times in the face, and never speaks another word.",
        "creator": "Alex Michaelides",
        "year": 2019
    },
    {
        "title": "Gone Girl",
        "item_type": "Book",
        "genre": "Mystery",
        "rating": 8.1,
        "synopsis": "On their fifth wedding anniversary, Nick Dunne reports that his beautiful wife Amy has disappeared. Under pressure from police, Nick's story begins to unravel.",
        "creator": "Gillian Flynn",
        "year": 2012
    },
    {
        "title": "Atomic Habits",
        "item_type": "Book",
        "genre": "Non-Fiction",
        "rating": 8.8,
        "synopsis": "A practical framework for self-improvement that teaches how small daily habits compound into remarkable personal and professional transformations.",
        "creator": "James Clear",
        "year": 2018
    },
    {
        "title": "Sapiens: A Brief History of Humankind",
        "item_type": "Book",
        "genre": "Non-Fiction",
        "rating": 8.6,
        "synopsis": "Dr. Yuval Noah Harari spans human history from the Stone Age to the modern age, exploring how Homo sapiens came to dominate planet Earth through shared myths.",
        "creator": "Yuval Noah Harari",
        "year": 2011
    },
    {
        "title": "The Da Vinci Code",
        "item_type": "Book",
        "genre": "Mystery",
        "rating": 7.9,
        "synopsis": "Symbologist Robert Langdon and cryptologist Sophie Neveu unravel a murder mystery at the Louvre that uncovers an ancient secret society secret.",
        "creator": "Dan Brown",
        "year": 2003
    },
    {
        "title": "Klara and the Sun",
        "item_type": "Book",
        "genre": "Sci-Fi",
        "rating": 8.0,
        "synopsis": "Klara, an Artificial Friend with outstanding observational qualities, watches the behavior of those who come in to browse the store and hopes for a family to choose her.",
        "creator": "Kazuo Ishiguro",
        "year": 2021
    },
    {
        "title": "Pride and Prejudice",
        "item_type": "Book",
        "genre": "Romance",
        "rating": 8.6,
        "synopsis": "The turbulent relationship between Elizabeth Bennet, the daughter of a country gentleman, and Fitzwilliam Darcy, a rich aristocratic landowner.",
        "creator": "Jane Austen",
        "year": 1813
    },
    {
        "title": "Foundation",
        "item_type": "Book",
        "genre": "Sci-Fi",
        "rating": 8.5,
        "synopsis": "Psychohistorian Hari Seldon predicts the inevitable fall of the Galactic Empire and creates a foundation of scholars to preserve human knowledge for future dark ages.",
        "creator": "Isaac Asimov",
        "year": 1951
    }
]
