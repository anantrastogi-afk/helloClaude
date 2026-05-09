import Foundation

struct ProblemBank {

    static let all: [Problem] = grade3 + grade4 + grade5

    static func problems(for grade: Grade, topic: Topic? = nil, competition: Competition? = nil) -> [Problem] {
        all.filter { p in
            p.grade == grade &&
            (topic == nil || p.topic == topic) &&
            (competition == nil || p.competition == competition)
        }
    }

    static func randomProblems(grade: Grade, competition: Competition, count: Int) -> [Problem] {
        let pool = all.filter { $0.grade == grade && $0.competition == competition }
        let fallback = all.filter { $0.grade == grade }
        let source = pool.count >= count ? pool : fallback
        return Array(source.shuffled().prefix(count))
    }

    // MARK: - Grade 3

    private static let grade3: [Problem] = [
        // Arithmetic
        Problem(id: UUID(), question: "What is 37 × 6?",
                options: ["222", "212", "232", "202"], correctAnswerIndex: 0,
                explanation: "37 × 6 = 30×6 + 7×6 = 180 + 42 = 222.",
                topic: .arithmetic, difficulty: .easy, grade: .third, competition: .general),

        Problem(id: UUID(), question: "What is 168 ÷ 8?",
                options: ["21", "23", "19", "25"], correctAnswerIndex: 0,
                explanation: "8 × 21 = 168, so 168 ÷ 8 = 21.",
                topic: .arithmetic, difficulty: .easy, grade: .third, competition: .general),

        Problem(id: UUID(), question: "What is 25 × 4 × 2?",
                options: ["180", "200", "240", "160"], correctAnswerIndex: 1,
                explanation: "Multiply in a smart order: 25 × 4 = 100, then 100 × 2 = 200.",
                topic: .arithmetic, difficulty: .medium, grade: .third, competition: .mathcounts),

        Problem(id: UUID(), question: "What is 9 × 9 − 8 × 8?",
                options: ["15", "17", "19", "16"], correctAnswerIndex: 1,
                explanation: "9² − 8² = (9+8)(9−8) = 17 × 1 = 17.",
                topic: .arithmetic, difficulty: .medium, grade: .third, competition: .amc8),

        // Fractions
        Problem(id: UUID(), question: "Which fraction is equivalent to 2/4?",
                options: ["1/2", "1/3", "2/3", "3/4"], correctAnswerIndex: 0,
                explanation: "Divide numerator and denominator by 2: 2÷2=1, 4÷2=2, giving 1/2.",
                topic: .fractions, difficulty: .easy, grade: .third, competition: .general),

        Problem(id: UUID(), question: "What is 1/4 + 2/4?",
                options: ["2/8", "3/8", "3/4", "1/2"], correctAnswerIndex: 2,
                explanation: "Same denominator, so add numerators: 1+2=3, answer is 3/4.",
                topic: .fractions, difficulty: .easy, grade: .third, competition: .general),

        Problem(id: UUID(), question: "Which fraction is greater than 1/2?",
                options: ["1/3", "2/6", "3/4", "1/4"], correctAnswerIndex: 2,
                explanation: "3/4 = 0.75, which is greater than 1/2 = 0.5. The others are ≤ 1/2.",
                topic: .fractions, difficulty: .easy, grade: .third, competition: .general),

        Problem(id: UUID(), question: "There are 24 apples. 1/3 are red and the rest are green. How many are green?",
                options: ["8", "12", "16", "18"], correctAnswerIndex: 2,
                explanation: "1/3 of 24 = 8 red apples. Green = 24 − 8 = 16.",
                topic: .fractions, difficulty: .medium, grade: .third, competition: .mathcounts),

        // Geometry
        Problem(id: UUID(), question: "A rectangle has length 9 cm and width 4 cm. What is its area?",
                options: ["26 sq cm", "32 sq cm", "36 sq cm", "40 sq cm"], correctAnswerIndex: 2,
                explanation: "Area = length × width = 9 × 4 = 36 square centimeters.",
                topic: .geometry, difficulty: .easy, grade: .third, competition: .general),

        Problem(id: UUID(), question: "What is the perimeter of a square with side 7 m?",
                options: ["14 m", "21 m", "28 m", "49 m"], correctAnswerIndex: 2,
                explanation: "Perimeter = 4 × side = 4 × 7 = 28 meters.",
                topic: .geometry, difficulty: .easy, grade: .third, competition: .general),

        Problem(id: UUID(), question: "A rectangle has perimeter 30 cm. Its length is 9 cm. What is its width?",
                options: ["6 cm", "7 cm", "8 cm", "12 cm"], correctAnswerIndex: 0,
                explanation: "2 × (length + width) = 30, so length + width = 15. Width = 15 − 9 = 6 cm.",
                topic: .geometry, difficulty: .medium, grade: .third, competition: .mathcounts),

        Problem(id: UUID(), question: "How many degrees are in a straight line?",
                options: ["90°", "120°", "180°", "360°"], correctAnswerIndex: 2,
                explanation: "A straight line forms a straight angle, which is exactly 180°.",
                topic: .geometry, difficulty: .easy, grade: .third, competition: .general),

        // Word Problems
        Problem(id: UUID(), question: "Maria has 3 boxes with 24 cookies each. She gives away 15 cookies. How many does she have left?",
                options: ["47", "57", "67", "77"], correctAnswerIndex: 1,
                explanation: "Total: 3 × 24 = 72 cookies. After giving away: 72 − 15 = 57.",
                topic: .wordProblems, difficulty: .medium, grade: .third, competition: .general),

        Problem(id: UUID(), question: "A train travels 45 miles per hour. How far does it travel in 3 hours?",
                options: ["125 miles", "135 miles", "145 miles", "150 miles"], correctAnswerIndex: 1,
                explanation: "Distance = speed × time = 45 × 3 = 135 miles.",
                topic: .wordProblems, difficulty: .medium, grade: .third, competition: .mathcounts),

        Problem(id: UUID(), question: "Jake earns $8 per hour. He works 6 hours on Saturday and 4 hours on Sunday. How much does he earn total?",
                options: ["$72", "$80", "$88", "$96"], correctAnswerIndex: 1,
                explanation: "Total hours = 6 + 4 = 10 hours. Earnings = 10 × $8 = $80.",
                topic: .wordProblems, difficulty: .easy, grade: .third, competition: .general),

        // Number Theory
        Problem(id: UUID(), question: "Which of these numbers is prime?",
                options: ["9", "15", "11", "21"], correctAnswerIndex: 2,
                explanation: "11 is prime (divisible only by 1 and 11). 9=3×3, 15=3×5, 21=3×7.",
                topic: .numberTheory, difficulty: .easy, grade: .third, competition: .general),

        Problem(id: UUID(), question: "What is the GCF of 6 and 9?",
                options: ["1", "2", "3", "6"], correctAnswerIndex: 2,
                explanation: "Factors of 6: 1, 2, 3, 6. Factors of 9: 1, 3, 9. GCF = 3.",
                topic: .numberTheory, difficulty: .easy, grade: .third, competition: .general),

        Problem(id: UUID(), question: "How many factors does 12 have?",
                options: ["4", "5", "6", "7"], correctAnswerIndex: 2,
                explanation: "Factors of 12: 1, 2, 3, 4, 6, 12 — that's 6 factors.",
                topic: .numberTheory, difficulty: .easy, grade: .third, competition: .amc8),

        // Patterns
        Problem(id: UUID(), question: "What comes next: 4, 8, 12, 16, ___?",
                options: ["18", "20", "22", "24"], correctAnswerIndex: 1,
                explanation: "These are multiples of 4. Add 4 each time: 16 + 4 = 20.",
                topic: .patterns, difficulty: .easy, grade: .third, competition: .general),

        Problem(id: UUID(), question: "What is the 10th term of the sequence 5, 10, 15, 20, ...?",
                options: ["45", "50", "55", "60"], correctAnswerIndex: 1,
                explanation: "These are multiples of 5. The 10th term = 5 × 10 = 50.",
                topic: .patterns, difficulty: .easy, grade: .third, competition: .mathcounts),

        Problem(id: UUID(), question: "What comes next: 2, 4, 8, 16, ___?",
                options: ["24", "28", "32", "36"], correctAnswerIndex: 2,
                explanation: "Each term is doubled: 2×2=4, 4×2=8, 8×2=16, 16×2=32.",
                topic: .patterns, difficulty: .easy, grade: .third, competition: .general),
    ]

    // MARK: - Grade 4

    private static let grade4: [Problem] = [
        // Arithmetic
        Problem(id: UUID(), question: "What is 234 × 17?",
                options: ["3868", "3958", "3978", "4078"], correctAnswerIndex: 2,
                explanation: "234×17 = 234×10 + 234×7 = 2340 + 1638 = 3978.",
                topic: .arithmetic, difficulty: .medium, grade: .fourth, competition: .general),

        Problem(id: UUID(), question: "What is 2016 ÷ 24?",
                options: ["82", "84", "86", "88"], correctAnswerIndex: 1,
                explanation: "24 × 80 = 1920, 2016 − 1920 = 96, 96 ÷ 24 = 4. So 80 + 4 = 84.",
                topic: .arithmetic, difficulty: .medium, grade: .fourth, competition: .general),

        Problem(id: UUID(), question: "What is 15² − 12²?",
                options: ["69", "81", "99", "125"], correctAnswerIndex: 1,
                explanation: "15² = 225, 12² = 144. 225 − 144 = 81.",
                topic: .arithmetic, difficulty: .medium, grade: .fourth, competition: .amc8),

        Problem(id: UUID(), question: "What is the value of 3 + 4 × 5 − 2?",
                options: ["23", "21", "33", "19"], correctAnswerIndex: 1,
                explanation: "Order of operations: multiply first. 4×5=20. Then 3+20−2 = 21.",
                topic: .arithmetic, difficulty: .medium, grade: .fourth, competition: .general),

        // Fractions
        Problem(id: UUID(), question: "What is 3/4 + 2/3?",
                options: ["5/7", "1 1/12", "1 5/12", "5/12"], correctAnswerIndex: 2,
                explanation: "LCD of 4 and 3 is 12. 3/4 = 9/12, 2/3 = 8/12. Sum = 17/12 = 1 5/12.",
                topic: .fractions, difficulty: .medium, grade: .fourth, competition: .general),

        Problem(id: UUID(), question: "What is 5/6 − 1/4?",
                options: ["4/10", "4/6", "7/12", "7/24"], correctAnswerIndex: 2,
                explanation: "LCD of 6 and 4 is 12. 5/6=10/12, 1/4=3/12. 10/12 − 3/12 = 7/12.",
                topic: .fractions, difficulty: .medium, grade: .fourth, competition: .general),

        Problem(id: UUID(), question: "What is 2½ × 4?",
                options: ["8", "9", "10", "11"], correctAnswerIndex: 2,
                explanation: "2½ = 5/2. (5/2) × 4 = 20/2 = 10.",
                topic: .fractions, difficulty: .medium, grade: .fourth, competition: .mathcounts),

        Problem(id: UUID(), question: "Which fraction is between 1/2 and 2/3?",
                options: ["3/8", "7/12", "5/6", "1/3"], correctAnswerIndex: 1,
                explanation: "Convert to common denominators (24): 1/2=12/24, 2/3=16/24, 7/12=14/24. So 7/12 is between them.",
                topic: .fractions, difficulty: .hard, grade: .fourth, competition: .amc8),

        // Decimals
        Problem(id: UUID(), question: "What is 3.14 + 2.86?",
                options: ["5.90", "6.00", "6.10", "5.80"], correctAnswerIndex: 1,
                explanation: "0.14 + 0.86 = 1.00. So 3 + 2 + 1 = 6.00.",
                topic: .decimals, difficulty: .easy, grade: .fourth, competition: .general),

        Problem(id: UUID(), question: "What is 4.5 × 6?",
                options: ["24.5", "25.5", "26.5", "27.0"], correctAnswerIndex: 3,
                explanation: "4.5 × 6 = 4×6 + 0.5×6 = 24 + 3 = 27.0.",
                topic: .decimals, difficulty: .easy, grade: .fourth, competition: .general),

        Problem(id: UUID(), question: "What is 12.6 ÷ 0.3?",
                options: ["4.2", "42", "0.42", "420"], correctAnswerIndex: 1,
                explanation: "Multiply both by 10: 126 ÷ 3 = 42.",
                topic: .decimals, difficulty: .medium, grade: .fourth, competition: .mathcounts),

        Problem(id: UUID(), question: "What is 0.25 × 40?",
                options: ["8", "10", "12", "14"], correctAnswerIndex: 1,
                explanation: "0.25 = 1/4. (1/4) × 40 = 10.",
                topic: .decimals, difficulty: .easy, grade: .fourth, competition: .general),

        // Number Theory
        Problem(id: UUID(), question: "What is the LCM of 4 and 6?",
                options: ["6", "8", "12", "24"], correctAnswerIndex: 2,
                explanation: "Multiples of 4: 4, 8, 12, ... Multiples of 6: 6, 12, ... LCM = 12.",
                topic: .numberTheory, difficulty: .easy, grade: .fourth, competition: .general),

        Problem(id: UUID(), question: "How many factors does 36 have?",
                options: ["7", "8", "9", "10"], correctAnswerIndex: 2,
                explanation: "Factors of 36: 1, 2, 3, 4, 6, 9, 12, 18, 36 — that's 9 factors.",
                topic: .numberTheory, difficulty: .medium, grade: .fourth, competition: .amc8),

        Problem(id: UUID(), question: "What is the prime factorization of 60?",
                options: ["2 × 3 × 5²", "2² × 3 × 5", "2³ × 5", "2 × 5 × 6"], correctAnswerIndex: 1,
                explanation: "60 = 2×30 = 2×2×15 = 2²×3×5.",
                topic: .numberTheory, difficulty: .medium, grade: .fourth, competition: .mathcounts),

        Problem(id: UUID(), question: "Which of these is divisible by both 3 and 4?",
                options: ["22", "26", "36", "46"], correctAnswerIndex: 2,
                explanation: "Must be divisible by LCM(3,4)=12. 36÷12=3. ✓",
                topic: .numberTheory, difficulty: .medium, grade: .fourth, competition: .general),

        // Word Problems
        Problem(id: UUID(), question: "A book has 324 pages. Jake reads 1/4 on Monday and 1/3 on Tuesday. How many pages has he read?",
                options: ["162", "171", "189", "207"], correctAnswerIndex: 2,
                explanation: "1/4 of 324 = 81 pages. 1/3 of 324 = 108 pages. Total = 81 + 108 = 189.",
                topic: .wordProblems, difficulty: .medium, grade: .fourth, competition: .mathcounts),

        Problem(id: UUID(), question: "If 5 notebooks cost $8.75, how much do 8 notebooks cost?",
                options: ["$12.50", "$13.00", "$14.00", "$15.00"], correctAnswerIndex: 2,
                explanation: "Cost per notebook = $8.75 ÷ 5 = $1.75. Eight notebooks = 8 × $1.75 = $14.00.",
                topic: .wordProblems, difficulty: .medium, grade: .fourth, competition: .general),

        Problem(id: UUID(), question: "A pool holds 6000 liters. It is being filled at 250 liters per minute. How many minutes to fill it?",
                options: ["20", "22", "24", "30"], correctAnswerIndex: 2,
                explanation: "Time = 6000 ÷ 250 = 24 minutes.",
                topic: .wordProblems, difficulty: .medium, grade: .fourth, competition: .mathcounts),

        // Patterns
        Problem(id: UUID(), question: "What is the 15th term of the sequence 3, 7, 11, 15, ...?",
                options: ["55", "57", "59", "63"], correctAnswerIndex: 2,
                explanation: "Arithmetic sequence: first term 3, common difference 4. Term 15 = 3 + (15−1)×4 = 3+56 = 59.",
                topic: .patterns, difficulty: .medium, grade: .fourth, competition: .mathcounts),

        Problem(id: UUID(), question: "In the sequence 1, 1, 2, 3, 5, 8, ___, what comes next?",
                options: ["11", "12", "13", "14"], correctAnswerIndex: 2,
                explanation: "Fibonacci sequence: each term = sum of two previous. 5+8 = 13.",
                topic: .patterns, difficulty: .medium, grade: .fourth, competition: .amc8),

        Problem(id: UUID(), question: "What is the units digit of 4^10?",
                options: ["2", "4", "6", "8"], correctAnswerIndex: 2,
                explanation: "Powers of 4 cycle: 4¹=4, 4²=16, 4³=64, 4⁴=256. Odd powers end in 4, even powers end in 6. 4^10 has an even exponent → units digit 6.",
                topic: .patterns, difficulty: .hard, grade: .fourth, competition: .amc8),
    ]

    // MARK: - Grade 5

    private static let grade5: [Problem] = [
        // Fractions
        Problem(id: UUID(), question: "What is 3⅖ ÷ 1⅕?",
                options: ["2 5/6", "2 7/6", "3", "2 1/2"], correctAnswerIndex: 0,
                explanation: "3⅖ = 17/5, 1⅕ = 6/5. (17/5) ÷ (6/5) = 17/5 × 5/6 = 17/6 = 2⅚.",
                topic: .fractions, difficulty: .hard, grade: .fifth, competition: .mathcounts),

        Problem(id: UUID(), question: "What is 2/3 of 4/5 of 90?",
                options: ["36", "48", "54", "60"], correctAnswerIndex: 1,
                explanation: "4/5 × 90 = 72. Then 2/3 × 72 = 48.",
                topic: .fractions, difficulty: .medium, grade: .fifth, competition: .general),

        Problem(id: UUID(), question: "Express 5/8 as a decimal.",
                options: ["0.525", "0.575", "0.625", "0.725"], correctAnswerIndex: 2,
                explanation: "5 ÷ 8 = 0.625. Alternatively, 5/8 = 625/1000 = 0.625.",
                topic: .fractions, difficulty: .easy, grade: .fifth, competition: .general),

        Problem(id: UUID(), question: "What fraction of 2 hours is 45 minutes?",
                options: ["1/4", "3/8", "3/4", "5/8"], correctAnswerIndex: 1,
                explanation: "2 hours = 120 minutes. 45/120 = 3/8.",
                topic: .fractions, difficulty: .medium, grade: .fifth, competition: .amc8),

        // Decimals
        Problem(id: UUID(), question: "What is 1.5² − 0.5²?",
                options: ["1.5", "2.0", "2.5", "3.0"], correctAnswerIndex: 1,
                explanation: "1.5² = 2.25, 0.5² = 0.25. 2.25 − 0.25 = 2.00.",
                topic: .decimals, difficulty: .medium, grade: .fifth, competition: .mathcounts),

        Problem(id: UUID(), question: "What is 0.1 + 0.01 + 0.001?",
                options: ["0.111", "0.0111", "1.011", "0.1011"], correctAnswerIndex: 0,
                explanation: "Line up decimal points: 0.100 + 0.010 + 0.001 = 0.111.",
                topic: .decimals, difficulty: .easy, grade: .fifth, competition: .general),

        Problem(id: UUID(), question: "A ribbon is 2.4 m long. It is cut into pieces of 0.15 m each. How many pieces are there?",
                options: ["12", "14", "16", "18"], correctAnswerIndex: 2,
                explanation: "2.4 ÷ 0.15 = 240 ÷ 15 = 16 pieces.",
                topic: .decimals, difficulty: .medium, grade: .fifth, competition: .mathcounts),

        // Algebra
        Problem(id: UUID(), question: "If 3x + 7 = 22, what is x?",
                options: ["3", "4", "5", "6"], correctAnswerIndex: 2,
                explanation: "3x + 7 = 22 → 3x = 15 → x = 5.",
                topic: .algebra, difficulty: .easy, grade: .fifth, competition: .general),

        Problem(id: UUID(), question: "If a + b = 10 and a − b = 4, what is a × b?",
                options: ["18", "21", "24", "27"], correctAnswerIndex: 1,
                explanation: "Add equations: 2a = 14, a = 7. Then b = 3. a × b = 7 × 3 = 21.",
                topic: .algebra, difficulty: .medium, grade: .fifth, competition: .mathcounts),

        Problem(id: UUID(), question: "What is the sum of all integers from 1 to 50?",
                options: ["1225", "1250", "1275", "1300"], correctAnswerIndex: 2,
                explanation: "Sum = n(n+1)/2 = 50×51/2 = 25×51 = 1275.",
                topic: .algebra, difficulty: .medium, grade: .fifth, competition: .amc8),

        Problem(id: UUID(), question: "If 5 workers complete a job in 6 days, how many days will 10 workers take?",
                options: ["2 days", "3 days", "4 days", "5 days"], correctAnswerIndex: 1,
                explanation: "Total work = 5×6 = 30 worker-days. With 10 workers: 30÷10 = 3 days.",
                topic: .algebra, difficulty: .medium, grade: .fifth, competition: .mathcounts),

        // Geometry
        Problem(id: UUID(), question: "What is the area of a triangle with base 12 cm and height 8 cm?",
                options: ["40 sq cm", "48 sq cm", "56 sq cm", "96 sq cm"], correctAnswerIndex: 1,
                explanation: "Area = ½ × base × height = ½ × 12 × 8 = 48 sq cm.",
                topic: .geometry, difficulty: .easy, grade: .fifth, competition: .general),

        Problem(id: UUID(), question: "A box has length 5 cm, width 4 cm, height 3 cm. What is its volume?",
                options: ["47 cu cm", "55 cu cm", "60 cu cm", "72 cu cm"], correctAnswerIndex: 2,
                explanation: "Volume = l×w×h = 5×4×3 = 60 cubic cm.",
                topic: .geometry, difficulty: .easy, grade: .fifth, competition: .general),

        Problem(id: UUID(), question: "The angles of a triangle are in the ratio 2:3:5. What is the largest angle?",
                options: ["54°", "72°", "90°", "108°"], correctAnswerIndex: 2,
                explanation: "2x+3x+5x = 180°, so 10x = 180°, x = 18°. Largest angle = 5×18° = 90°.",
                topic: .geometry, difficulty: .medium, grade: .fifth, competition: .amc8),

        Problem(id: UUID(), question: "A circle has radius 5. What is its area? (Use π ≈ 3.14)",
                options: ["31.4", "62.8", "78.5", "157"], correctAnswerIndex: 2,
                explanation: "Area = π × r² = 3.14 × 25 = 78.5 square units.",
                topic: .geometry, difficulty: .medium, grade: .fifth, competition: .mathcounts),

        // Number Theory
        Problem(id: UUID(), question: "What is the LCM of 12, 15, and 20?",
                options: ["60", "90", "120", "180"], correctAnswerIndex: 0,
                explanation: "12=2²×3, 15=3×5, 20=2²×5. LCM = 2²×3×5 = 60.",
                topic: .numberTheory, difficulty: .medium, grade: .fifth, competition: .mathcounts),

        Problem(id: UUID(), question: "What is the GCF of 48 and 72?",
                options: ["12", "16", "24", "36"], correctAnswerIndex: 2,
                explanation: "48=2⁴×3, 72=2³×3². GCF = 2³×3 = 24.",
                topic: .numberTheory, difficulty: .medium, grade: .fifth, competition: .general),

        Problem(id: UUID(), question: "How many positive integers less than 50 are divisible by both 3 and 5?",
                options: ["2", "3", "4", "5"], correctAnswerIndex: 1,
                explanation: "Need multiples of LCM(3,5)=15. Multiples of 15 less than 50: 15, 30, 45 — that's 3.",
                topic: .numberTheory, difficulty: .medium, grade: .fifth, competition: .amc8),

        Problem(id: UUID(), question: "What is the ones digit of 7^2024?",
                options: ["1", "3", "7", "9"], correctAnswerIndex: 0,
                explanation: "Ones digits of powers of 7 cycle: 7,9,3,1,7,9,3,1,... (period 4). 2024÷4=506 remainder 0, so same as 7⁴ → ones digit 1.",
                topic: .numberTheory, difficulty: .hard, grade: .fifth, competition: .amc8),

        // Word Problems
        Problem(id: UUID(), question: "A jacket costs $75 and is on 30% off sale. What is the sale price?",
                options: ["$45.00", "$47.50", "$52.50", "$55.00"], correctAnswerIndex: 2,
                explanation: "Discount = 30% of $75 = $22.50. Sale price = $75 − $22.50 = $52.50.",
                topic: .wordProblems, difficulty: .medium, grade: .fifth, competition: .general),

        Problem(id: UUID(), question: "A car travels 240 miles in 4 hours. At the same speed, how long to travel 360 miles?",
                options: ["5 hours", "6 hours", "7 hours", "8 hours"], correctAnswerIndex: 1,
                explanation: "Speed = 240÷4 = 60 mph. Time = 360÷60 = 6 hours.",
                topic: .wordProblems, difficulty: .medium, grade: .fifth, competition: .general),

        Problem(id: UUID(), question: "If 3/5 of a class of 40 students are girls, how many are boys?",
                options: ["14", "16", "20", "24"], correctAnswerIndex: 1,
                explanation: "Girls = 3/5 × 40 = 24. Boys = 40 − 24 = 16.",
                topic: .wordProblems, difficulty: .easy, grade: .fifth, competition: .general),

        Problem(id: UUID(), question: "A 3×3×3 cube is painted on all sides then cut into 27 unit cubes. How many unit cubes have exactly 2 faces painted?",
                options: ["8", "12", "6", "4"], correctAnswerIndex: 1,
                explanation: "Edge cubes (non-corner) have 2 painted faces. A cube has 12 edges, each with 1 such cube in the middle, giving 12 unit cubes.",
                topic: .wordProblems, difficulty: .hard, grade: .fifth, competition: .amc8),

        Problem(id: UUID(), question: "In how many ways can you make change for 25 cents using only nickels and dimes?",
                options: ["2", "3", "4", "5"], correctAnswerIndex: 1,
                explanation: "Options: (0 dimes, 5 nickels), (1 dime, 3 nickels), (2 dimes, 1 nickel) — 3 ways.",
                topic: .wordProblems, difficulty: .medium, grade: .fifth, competition: .mathcounts),
    ]
}
