
push = require 'push'

Class = require 'class'

require 'Paddle'

require 'Ball'

--tamaño del windows 
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- tamaño con el que el juego va a empujar
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- velocidad de la paleta
PADDLE_SPEED = 350


local background = love.graphics.newImage('background.png')
local ball = love.graphics.newImage('ball.png')

function love.load()
    --filtro de suavidad 
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- titulo de la app de windows
    love.window.setTitle('Poke-Pong')

    -- seed RNG para volver random
    math.randomseed(os.time())

    -- Fuente y sus tamaños
    littleFont = love.graphics.newFont('font2.ttf', 10)
    smallFont = love.graphics.newFont('font.ttf', 20)
    largeFont = love.graphics.newFont('font.ttf', 30)
    scoreFont = love.graphics.newFont('font.ttf', 40)
    pokeFont = love.graphics.newFont('pokefont.otf', 32)

    love.graphics.setFont(smallFont)

    -- biblioteca de sonidos
    sounds = {
        ['music'] = love.audio.newSource('sounds/music.mp3', 'static'),
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.mp3', 'static'),
        ['score'] = love.audio.newSource('sounds/score.mp3', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.mp3', 'static'),
        ['win'] = love.audio.newSource('sounds/win.mp3', 'static')
        
    }
    
    -- iniciar la musica
    sounds['music']:setLooping(true)
    sounds['music']:play()

    -- empieza con la resolucion virtual sin importar la de windows
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true,
        canvas = false
    })

    -- Paletas
    player1 = Paddle(10, 30, 5, 30)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 30)

    -- pelota en medio de la pantalla
    ball = Ball(VIRTUAL_WIDTH / 5 - 5, VIRTUAL_HEIGHT / 5 - 5, 10, 10)

    -- variables de puntos
    player1Score = 0
    player2Score = 0

    -- turnos
    servingPlayer = 1


    winningPlayer = 0

    -- Estados del juego:
    -- 1. 'start' (empezando el juego antes de servir)
    -- 2. 'serve' (apretar una tecla para empezar a jugar)
    -- 3. 'play' (la pelota empieza a rebotar entre las paletas)
    -- 4. 'done' (el juego termina con un ganador, esperando a volver a empezar)
    gameState = 'start'
end

-- Empuja las dimensiones de la pantalla
function love.resize(w, h)
    push:resize(w, h)
end


function love.update(dt)
    if gameState == 'serve' then
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    elseif gameState == 'play' then

-- detecta las colisiones
        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + 5

            -- mantiene la velocidad en la misma direccion, pero rebotando de modo random
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4

            -- mantiene la velocidad en la misma direccion, pero rebotando de modo random

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end

        -- detecta las colisiones con piso y techo con un sonido y lo hace rebotar
    
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- -4 es el tamaño de la pelota
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- si llega al borde izq o der vuelve a servir
        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()

            -- si llega a 10 gana alguien y sale el estado de victoria
            if player2Score == 10 then
                winningPlayer = 2
                sounds['music']:stop()
                sounds['win']:play()
                gameState = 'done'                
            else
                sounds['music']:play()
                gameState = 'serve'
                -- pone la bola en el medio de la pantalla
                ball:reset()
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()

            if player1Score == 10 then
                winningPlayer = 1
                sounds['music']:stop()
                sounds['win']:play()
                gameState = 'done'
            else
                sounds['music']:play()
                gameState = 'serve'
                ball:reset()
            end
        end
    end
    

    --
    -- las paletas pueden moverse sin importar su estado
    --
    -- player 1
    if aiModePlayer1 then
        player1.y = ball.y
    elseif love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

--Player 2 como persona o IA
    if aiModePlayer2 then
        player2.y = ball.y
    elseif love.keyboard.isDown('up') then
            player2.dy = -PADDLE_SPEED
        elseif love.keyboard.isDown('down') then
            player2.dy = PADDLE_SPEED
        else
            player2.dy = 0
        end


    --[[
    -- player 2 [[
    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end
]]

    -- actualiza la bola en estado DY DX si estamos en estado de juego
    -- escalar la velocidad en dt para que el movimiento sea independiente de la velocidad de fotogramas
    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end

-- Tecla para salir
function love.keypressed(key)

    --Activador de AI
    if key == 'x' and gameState == 'start' then
        aiModePlayer2 = true
    end
 
    if key == 'v' and gameState == 'play' then
        aiModePlayer2 = false
    end

    if key == 'x' and gameState == 'play' then
        aiModePlayer2 = true 
    end

    if key == 'z' and gameState == 'start' then
        aiModePlayer1 = true
    end
 
    if key == 'c' and gameState == 'play' then
        aiModePlayer1 = false
    end

    if key == 'z' and gameState == 'play' then
        aiModePlayer1 = true 
    end


    if key == 'escape' then
        love.event.quit()
    --si apretamos enter durante la fase de inicio o servicio, pasa al siguiente estado
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            -- Fase de reinicio y saca el jugador ganador
            gameState = 'serve'

            ball:reset()

            -- vuelve la puntuacion a 0
            player1Score = 0
            player2Score = 0

            -- Decide servir al jugador contrario al que gano
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end

-- dibujos
function love.draw()
    push:start()
    
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(background, 0)
    

    if gameState == 'start' then
        -- UI mensaje
        love.graphics.setFont(pokeFont)
        love.graphics.setColor(1, 0.9, 0)
        love.graphics.printf('Poke - pong', 0, 10, VIRTUAL_WIDTH, 'center')

        love.graphics.setFont(smallFont)
       -- love.graphics.setColor(0, 0, 0)
        love.graphics.printf('(Apretá ENTER para la batalla)', 0, 40, VIRTUAL_WIDTH, 'center')
        
        love.graphics.setFont(littleFont)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf('Arriba: W', 20, 210, VIRTUAL_WIDTH, 'left')
        love.graphics.printf('Abajo:  S', 20, 220, VIRTUAL_WIDTH, 'left')
        love.graphics.printf('Arriba: Flecha arriba', -20, 210, VIRTUAL_WIDTH, 'right')
        love.graphics.printf(' Abajo:  Flecha Abajo', -20, 220, VIRTUAL_WIDTH, 'right')

        love.graphics.printf('Apreta x para jugar VS BOT', -20, 150, VIRTUAL_WIDTH, 'right')


        love.graphics.setFont(pokeFont)
        love.graphics.setColor(1, 0.9, 0)
        love.graphics.printf('controles:', 0, 160, VIRTUAL_WIDTH, 'center')


    end
        
    if gameState == 'serve' then
        -- UI mensaje
        love.graphics.setFont(smallFont)
        love.graphics.setColor(1, 0.9, 0)

        love.graphics.printf('(El entrenador ' .. tostring(servingPlayer) .. " ataca)", 
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('(ENTER para atacar)', 0, 30, VIRTUAL_WIDTH, 'center')

        love.graphics.setFont(littleFont)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf('Activar:', 20, 180, VIRTUAL_WIDTH, 'left')    
        love.graphics.printf('Z = Bot 1', 20, 190, VIRTUAL_WIDTH, 'left')    
        love.graphics.printf('x = Bot 2', 20, 200, VIRTUAL_WIDTH, 'left')    
        love.graphics.printf('c = Entrenador 1', 20, 210, VIRTUAL_WIDTH, 'left')    
        love.graphics.printf('v = Entrenador 2', 20, 220, VIRTUAL_WIDTH, 'left') 
    end


    if gameState == 'play' then

        love.graphics.setFont(littleFont)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf('Activar:', 20, 180, VIRTUAL_WIDTH, 'left')    
        love.graphics.printf('Z = Bot 1', 20, 190, VIRTUAL_WIDTH, 'left')    
        love.graphics.printf('x = Bot 2', 20, 200, VIRTUAL_WIDTH, 'left')    
        love.graphics.printf('c = Entrenador 1', 20, 210, VIRTUAL_WIDTH, 'left')    
        love.graphics.printf('v = Entrenador 2', 20, 220, VIRTUAL_WIDTH, 'left')  
    end

    if gameState == 'done' then
        -- UI messages
        love.graphics.setFont(largeFont)
        love.graphics.setColor(1, 0.9, 0)
        love.graphics.printf(' EL ENTRENADOR ' .. tostring(winningPlayer) .. ' HA GANADO EL DUELO',
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('ENTER para la revancha', 0, 190, VIRTUAL_WIDTH, 'center')
    end

    -- muestra el score por debajo de la pelota
    displayScore()
    
    player1:render()
    player2:render()
    ball:render()

    -- muestra los fps como comentario (desactivado)
   -- displayFPS()
    
    -- empujar el dibujo
    push:finish()
end

--renderizar los scores
function displayScore()
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 100,
        VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 80,
        VIRTUAL_HEIGHT / 3)
end
-- mostrar FPS (desactivado)
--[[function displayFPS()
    -- simple FPS display across all states
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255/255, 0, 255/255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.setColor(255, 255, 255, 255)
end 
]]