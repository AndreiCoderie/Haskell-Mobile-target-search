{-# OPTIONS_GHC -Wall #-}
{-# LANGUAGE EmptyDataDecls, MultiParamTypeClasses,
             TypeSynonymInstances, FlexibleInstances,
             InstanceSigs #-}

module Basics where
{-
    Expune funcțiile necesare reprezentării jocului.
-}

import ProblemState
import Data.List
import Data.Maybe

{-
    Sinonim tip de date pentru reprezetarea unei perechi (Int, Int)
    care va reține coordonatele celulelor de pe tabla de joc.
    Colțul stânga-sus este (0, 0).
-}
type Position = (Int, Int)

{-
    Tip de date pentru reprezentarea Target-urilor.
    Acestea conțin informații atât despre poziția curentă a
    Target-ului cât și despre comportamentul acestuia.
    Tipul Behavior este definit mai jos.
-}
data Target = Target {
    position :: Position,
    behavior :: Behavior
}

instance Eq Target where
    Target p1 _ == Target p2 _ = p1 == p2

instance Ord Target where
    Target p1 _ <= Target p2 _ = p1 <= p2

{-
    Tip de date pentru reprezentarea comportamentului unui Target.
    Tipul Behavior este utilizat pentru a modela tranziția Target-urilor
    din starea curentă în starea următoare. Primul parametru este poziția
    actuală a target-ului, iar al doilea, starea curentă a jocului.
    Tipul Game este definit mai jos.
    
    Observați că, din moment ce un Behavior produce un Target nou,
    acesta din urmă ar putea fi caracterizat de un alt Behavior
    decât cel anterior.
-}
type Behavior = Position -> Game -> Target

{-
    Direcțiile de deplasare pe tablă
-}
data Direction = North | South | West | East
    deriving (Eq, Show)

{-
    *** TODO ***
    
    Tip de date pentru reprezentarea stării jocului, la un anumit
    moment. Completați-l cu orice informație aveți nevoie pentru
    stocarea stării jocului (hunter, target, obstacole, gateways).
-}
data Game = Game {
        hunter :: Position,
        target :: [Target],
        obst :: [Position],
        gatew :: [(Position, Position)],
        n :: Int,
        m :: Int
        }  deriving (Eq, Ord)
{-
    *** Optional *** 
  
    Dacă aveți nevoie de o funcționalitate particulară,
    instantiați explicit clasele Eq și Ord pentru Game.
    În cazul acesta, eliminați deriving (Eq, Ord) din Game.
-}

{-
    *** TODO ***

    Reprezentați starea jocului ca șir de caractere, pentru afișarea
    la consolă.
    
    Atenție! Fiecare linie, mai puțin ultima, este urmată de \n.
    Celule goale vor fi reprezentate ca ' '.
    Hunter-ul va fi reprezentat ca '!'.
    Target-urile vor fi reprezentate ca '*'
    Gateways-urile vor fi reprezentate ca '#'.
    Obstacolele vor fi reprezentate de '@'.

    Hint: S-ar putea să vă fie utile list comprehensions,
    precum și funcțiile elem, any și intercalate din Data.List.
-}
gameAsString :: Game -> String
gameAsString game = concatMap(testFunction game "") [(x,y) | x <- [0 ..(n game) - 1], y <- [0.. (m game) - 1]] 

testFunction game stringVid pair
            | (hunter game) == pair && (fst pair /= (n game) - 1) && (snd pair == (m game) - 1) = stringVid ++ "!\n"
            | elem pair (map position (target game)) == True && (fst pair /= (n game) - 1) && (snd pair == (m game) - 1) = stringVid ++ "*\n"
            | elem pair ((map fst (gatew game)) ++ (map snd (gatew game))) == True && (fst pair /= (n game) -1) && (snd pair == (m game )- 1) = stringVid ++ "#\n"
            | elem pair (obst game) == True && (fst pair /= (n game) - 1) && (snd pair == (m game) - 1) = stringVid ++ "@\n"
            | (hunter game) == pair = stringVid ++ "!"
            | elem pair (map position (target game)) == True = stringVid ++ "*"
            | elem pair ((map fst (gatew game)) ++ (map snd (gatew game))) == True = stringVid ++ "#"
            | elem pair (obst game) == True = stringVid ++ "@"
            | otherwise = stringVid ++ " "

instance Show Game where
    show = gameAsString

{-
    *** TODO ***
    
    Primește numărul de linii și numărul de coloane ale tablei de joc.
    Intoarce un obiect de tip Game în care tabla conține spații goale în interior, fiind
    împrejmuită de obstacole pe toate laturile. Implicit, colțul din stânga sus este (0,0),
    iar Hunterul se găsește pe poziția (1, 1).
-}
emptyGame :: Int -> Int -> Game
emptyGame a b = (Game (1,1) [] ([(x,y) | x <- [0 , a-1], y <- [0 ..b-1]] ++ [(x,y) | x <- [0 .. a-1], y <- [0, b-1]]) [] a b)


{-
    *** TODO ***

    Primește o poziție și un joc și întoarce un nou joc, cu Hunter-ul pus
    pe poziția specificată.
    Parametrul Position reprezintă poziția de pe hartă la care va fi adaugat Hunter-ul
    Daca poziția este invalidă (ocupată sau în afara tablei de joc) se va întoarce
    același joc.
-}
addHunter :: Position -> Game -> Game
addHunter  pos game =
    if(elem pos ([(x,y) | x <- [0 .. ((n game) -1)] , y <- [0 .. ((m game) - 1)]]) == True
     && (elem pos (obst game) == False)) then  (Game pos (target game) 
    (obst game) (gatew game) (n game) (m game))
    else
     game

{-
    *** TODO ***

    Primește un comportament, o poziție și un joc și întoarce un nou joc, în care a fost
    adăugat Target-ul descris de comportament și poziție.
    Parametrul Behavior reprezintă comportamentul Hunter-ului care va fi adăugat.
    Parametrul Position reprezintă poziția de pe hartă la care va fi adăugat Target-ul.
-}
addTarget :: Behavior -> Position -> Game -> Game
addTarget behav pos game = 
        Game (hunter game) (target game ++ [Target pos behav]) (obst game) (gatew game) (n game) (m game)

{-
    *** TODO ***

    Primește o pereche de poziții și un joc și întoarce un nou joc, în care au fost adăugate
    cele două gateway-uri interconectate.
    Parametrul (Position, Position) reprezintă pozițiile de pe hartă la care vor fi adăugate 
    cele două gateway-uri interconectate printr-un canal bidirecțional.
-} 
addGateway :: (Position, Position) -> Game -> Game
addGateway pair game = Game (hunter game) (target game) (obst game) ((gatew game) ++ [pair]) (n game) (m game)

{-
    *** TODO ***

    Primește o poziție și un joc și întoarce un nou joc, în care a fost adăugat un obstacol
    la poziția specificată.
    Parametrul Position reprezintă poziția de pe hartă la care va fi adăugat obstacolul.
-}
addObstacle :: Position -> Game -> Game
addObstacle pos game = Game (hunter game) (target game) (obst game ++ [pos]) (gatew game) (n game) (m game) 

{-
    *** TODO ***
    
    Primește o poziție destinație înspre care vrea să se deplaseze o entitate (Hunter sau Target)
    și verifică daca deplasarea este posibilă, întorcând noua poziție, luând în considerare
    și Gateway-urile.
    Avem următoarele cazuri:
    - dacă poziția corespunde unui spațiu gol, se întoarce acea poziție;
    - dacă poziția corespunde unui gateway, se întoarce poziția gateway-ului pereche;
    - dacă poziția corespunde unui obstacol, se întoarce Nothing.
    Parametrul Position reprezintă poziția destinație.
-}
attemptMove :: Position -> Game -> Maybe Position
attemptMove pos game 
    | elem pos (obst game) == True = Nothing
    | elem pos (map fst (gatew game)) == True = Just $ snd (head (filter (\x -> fst x == pos)  (gatew game)))
    | elem pos (map snd (gatew game)) == True = Just $ fst (head (filter (\x -> snd x == pos)  (gatew game)))    
   {- | pos == head(tail (gatew game)) = Just(head(gatew game))-} 
    | otherwise = Just(pos)

{-
    *** TODO ***

    Comportamentul unui Target de a se deplasa cu o casuță înspre est. 
    Miscarea se poate face doar daca poziția este validă (se află pe tabla de
    joc) și nu este ocupată de un obstacol. In caz contrar, Target-ul va rămâne 
    pe loc.
    
    Conform definiției, tipul Behavior corespunde tipului funcție
    Position -> Game -> Target.
    
    Având în vedere că cele patru funcții definite în continuare (goEast, goWest,
    goNorth, goSouth) sunt foarte similare, încercați să implementați o funcție
    mai generală, pe baza căreia să le definiți apoi pe acestea patru.
-}


{- funcite deupdatat target -}

behaviorf pos game x y f
    | (attemptMove ((fst pos) + x , ((snd pos) + y)) game) /= Nothing =
            (Target (fromJust (attemptMove ((fst pos) + x, ((snd pos) + y)) game)) f)
    | otherwise = (Target pos f)


    

goEast :: Behavior
goEast pos game = behaviorf pos game 0 1 goEast
{-
    *** TODO ***

    Comportamentul unui Target de a se deplasa cu o casuță înspre vest. 
    Miscarea se poate face doar daca poziția este validă (se află pe tabla de
    joc) și nu este ocupată de un obstacol. In caz contrar, Target-ul va rămâne 
    pe loc.
-}
goWest :: Behavior
goWest pos game = behaviorf pos game 0 (-1) goWest

{-
    *** TODO ***

    Comportamentul unui Target de a se deplasa cu o casuță înspre nord. 
    Miscarea se poate face doar daca poziția este validă (se află pe tabla de
    joc) și nu este ocupată de un obstacol. In caz contrar, Target-ul va rămâne 
    pe loc.
-}
goNorth :: Behavior
goNorth pos game = behaviorf pos game (-1) 0 goNorth

{-
    *** TODO ***

    Comportamentul unui Target de a se deplasa cu o casuță înspre sud. 
    Miscarea se poate face doar daca poziția este validă (se află pe tabla de
    joc) și nu este ocupată de un obstacol. In caz contrar, Target-ul va rămâne 
    pe loc.
-}
goSouth :: Behavior
goSouth pos game  = behaviorf pos game 1 0 goSouth

{-
    *** TODO ***

    Comportamentul unui Target de a-și oscila mișcarea, când înspre nord, când înspre sud. 
    Mișcarea se poate face doar dacă poziția este validă (se află pe tablă de
    joc) și nu este ocupată de un obstacol. In caz contrar, Target-ul iși va schimba
    direcția de mers astfel:
    - daca mergea inspre nord, își va modifica direcția miscării înspre sud;
    - daca mergea inspre sud, își va continua mișcarea înspre nord.
    Daca Target-ul întâlneste un Gateway pe traseul său, va trece prin acesta,
    către Gateway-ul pereche conectat și își va continua mișcarea în același sens la ieșire
    din acesta.
    Puteți folosit parametrul Int pentru a surprinde deplasamentul Target-ului (de exemplu,
    1 pentru sud, -1 pentru nord).
-}

goNorthBounce :: Behavior
goNorthBounce pos game
    | (attemptMove ((fst pos) - 1 , (snd pos)) game) /= Nothing =
            (Target (fromJust (attemptMove ((fst pos) - 1, (snd pos)) game)) goNorthBounce)
    | (attemptMove ((fst pos) - 1 , (snd pos)) game) == Nothing && (attemptMove ((fst(pos) +1), (snd pos)) game) /= Nothing = (Target (fromJust (attemptMove ((fst pos) + 1, (snd pos)) game)) goSouthBounce)
    
goSouthBounce :: Behavior    
goSouthBounce pos game
    | (attemptMove ((fst pos) + 1 , (snd pos)) game) /= Nothing =
            (Target (fromJust (attemptMove ((fst pos) + 1, (snd pos) ) game)) goSouthBounce)
    | (attemptMove ((fst pos) + 1 , (snd pos)) game) == Nothing && (attemptMove ((fst(pos) -1), (snd pos)) game) /= Nothing  = (Target (fromJust (attemptMove ((fst pos) - 1, (snd pos)) game)) goNorthBounce)

bounce :: Int -> Behavior
bounce x poss game
    {-| (attemptMove ((fst))-}
    | x == -1 = goNorthBounce poss game 
    | x == 1 = goSouthBounce poss game 

{-
    *** TODO ***
    Funcție care mută toate Target-urile din Game-ul dat o poziție, în functie
    de behavior-ul fiecăreia și întoarce noul Game în care pozițiile Target-urilor
    sunt actualizate.
    
-}





moveTargets :: Game -> Game
moveTargets game = Game (hunter game) (map (\x -> (behavior x) (position x) game)  (target game))
                    (obst game) (gatew game) (n game) (m game)
                    
                    
functieNebuna game target =
                (behavior target) (position target) game

{-
    *** TODO ***

    Verifică dacă Targetul va fi eliminat de Hunter.
    Un Target este eliminat de Hunter daca se află pe o poziție adiacentă
    cu acesta.
    Parametrul Position reprezintă poziția Hunterului pe tabla
    de joc.
    Parametrul Target reprezintă Targetul pentru care se face verificarea.
-}
checkIfDead pos target
    | (((fst pos) == (fst (position target)) + 1) && ((snd pos) /= (snd (position target)) +1) && ((snd pos ) /=
    (snd (position target)) - 1) || (((fst pos) == (fst (position target)) - 1) && ((snd pos) /= (snd (position target)) +1) && ((snd pos) /= (snd (position target)) - 1))||
    (((snd pos) == (snd (position target)) + 1) && ((fst pos) /= (fst (position target)) +1) &&
    ((fst pos) /= (fst (position target)) - 1)) || ((snd pos) == (snd (position target)) - 1) && ((fst pos) /= (fst (position target)) +1) && (fst pos ) /= ((fst (position target)) - 1)) = True
    | otherwise = False

isTargetKilled :: Position -> Target -> Bool
isTargetKilled pos target = checkIfDead pos target 


{-
    *** TODO ***

    Avansează starea jocului curent, rezultând starea următoare a jocului.
    Parametrul Direction reprezintă direcția în care se va deplasa Hunter-ul.
    Parametrul Bool specifică dacă, după mutarea Hunter-ului, vor fi
    mutate și Target-urile sau nu, și dacă vor fi eliminate din joc sau nu.
    Este folosit pentru a distinge între desfășurarea reală a jocului (True)
    și planificarea „imaginată” de hunter (False) în partea a doua a temei.

    Avansarea stării jocului respectă următoarea ordine:
    1. Se deplasează Hunter-ul.
    2. În funcție de parametrul Bool, se elimină Target-urile omorâte de către Hunter.
    3. In funcție de parametrul Bool, se deplasează Target-urile rămase pe tablă.
    4. Se elimină Targeturile omorâte de către Hunter și după deplasarea acestora.
    
    Dubla verificare a anihilării Target-urilor, în pașii 2 și 4, îi oferă Hunter-ului
    un avantaj în prinderea lor.
-}

changeHunter game directie = (Game (movTheHunter (hunter game) directie game) 
                (target game) (obst game) (gatew game) (n game) (m game))


targetKilled game  bool
    | bool == True = Game (hunter game)(filter (\x -> (isTargetKilled (hunter game) x) == False) (target game))
    (obst game) (gatew game) (n game) (m game)
    | otherwise = game
    
targetKilled2 game boolean 
    | boolean == True = moveTargets game
    | otherwise = game
    



movTheHunter hunter direction game
    | (direction == North && (attemptMove((fst hunter) -1, (snd hunter)) game) /= Nothing) = (fromJust (attemptMove((fst hunter) -1, (snd hunter)) game))
    | (direction == South
    && (attemptMove((fst hunter) +1, (snd hunter)) game) /= Nothing) = (fromJust (attemptMove((fst hunter) +1, (snd hunter)) game))
    | (direction == West 
    && (attemptMove((fst hunter), (snd hunter) -1) game) /= Nothing) = (fromJust (attemptMove((fst hunter), (snd hunter) -1) game))
    | (direction == East
    &&  (attemptMove((fst hunter), (snd hunter) +1) game) /= Nothing) = (fromJust (attemptMove((fst hunter), (snd hunter) +1) game))


advanceGameState :: Direction -> Bool -> Game -> Game
advanceGameState directie boolean game 
            =  (targetKilled2 (targetKilled (changeHunter game directie)  boolean) boolean)
    

{-(targetKilled (hunter (changeHunter game directie)) (target (targetKilled2 (targetKilled (hunter (changeHunter game directie)) (target (changeHunter game directie)) (changeHunter game directie)  boolean) boolean)) (targetKilled2 (targetKilled (hunter (changeHunter game directie)) (target (changeHunter game directie)) (changeHunter game directie)  boolean) boolean) boolean)-}

{-
    ***  TODO ***

    Verifică dacă mai există Target-uri pe table de joc.
-}
areTargetsLeft :: Game -> Bool
areTargetsLeft = undefined

{-
    *** BONUS TODO ***

    Comportamentul unui Target de a se deplasa în cerc, în jurul unui Position, având
    o rază fixată.
    Primul parametru, Position, reprezintă centrul cercului.
    Parametrul Int reprezintă raza cercului.
    Puteți testa utilizând terenul circle.txt din directorul terrains, în conjuncție
    cu funcția interactive.
-}
circle :: Position -> Int -> Behavior
circle = undefined


instance ProblemState Game Direction where
    {-
        *** TODO ***
        
        Generează succesorii stării curente a jocului.
        Utilizați advanceGameState, cu parametrul Bool ales corespunzător.
    -}
    successors = undefined

    {-
        *** TODO ***
        
        Verifică dacă starea curentă este un în care Hunter-ul poate anihila
        un Target. Puteți alege Target-ul cum doriți, în prezența mai multora.
    -}
    isGoal  = undefined

    {-
        *** TODO ***
        
        Euristica euclidiană (vezi hEuclidian mai jos) până la Target-ul ales
        de isGoal.
    -}
    h = undefined

{-
     ** NU MODIFICATI **
-}
hEuclidean :: Position -> Position -> Float
hEuclidean (x1, y1) (x2, y2) = fromIntegral $ ((x1 - x2) ^ pow) + ((y1 - y2) ^ pow)
  where
    pow = 2 :: Int

{-
    *** BONUS ***

    Acesta reprezintă un artificiu necesar pentru testarea bonusului,
    deoarece nu pot exista două instanțe diferite ale aceleiași clase
    pentru același tip.

    OBSERVAȚIE: Testarea bonusului pentru Seach este făcută separat.
-}

newtype BonusGame = BonusGame Game
    deriving (Eq, Ord, Show)

{-
    *** BONUS TODO ***

    Folosind wrapper-ul peste tipul Game de mai sus instanțiați
    ProblemState astfel încât să fie folosită noua euristică. 
-}
instance ProblemState BonusGame Direction where
    {-
        *** BONUS TODO ***

        Pentru a ne asigura că toțî succesorii unei stări sunt de tipul
        BonusGame și folosesc noua euristică trebuie să aplicăm wrapper-ul
        definit mai sus peste toți succesorii unei stări.

        Hint: Puteți să folosiți funcția fmap pe perechi pentru acest lucru.
        https://wiki.haskell.org/Functor
    -}
    successors = undefined

    {-
        *** BONUS TODO ***

        Definiți funcția isGoal pentru BonusGame.

        Hint: Folosiți funcția isGoal deja implementată pentru tipul Game.
    -}
    isGoal = undefined

    {-
        *** BONUS TODO ***

        Definiți o funcție euristică care este capabilă să găsească un drum mai scurt
        comparativ cu cel găsit de euristica implementată pentru Game.

        ATENȚIE: Noua euristică NU trebuie să fie una trivială.

        OBSERVAȚIE: Pentru testare se va folosi fișierul terrains/game-6.txt.
    -}
    h = undefined
