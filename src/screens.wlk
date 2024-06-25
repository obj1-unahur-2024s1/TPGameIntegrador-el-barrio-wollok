import wollok.game.*
import overcooked.*
import items.*
import tiles.*
import statusBar.*
import timer.*
import soundProducer.*

object administradorDePantalla {

	var property pantallaActual = menu

	var currentMusic

	method cambiarPantalla(nuevaPantalla) {
		game.clear()
		currentMusic.stop()
		pantallaActual = nuevaPantalla
		self.empezarPantalla()
	}

	method empezarPantalla() {
		background.image(pantallaActual.background())
		game.addVisual(background)
		game.schedule(10, { pantallaActual.indicarTeclas()}) // impide que la pantalla siguiente detecte la tecla de la ultima pantalla.	
		pantallaActual.show()
		currentMusic = soundProducer.sound("sounds/" + pantallaActual.backgroundMusic())
		game.schedule(500, {
			currentMusic.shouldLoop(true)
			currentMusic.play()
		})
	}

	method recipes() = pantallaActual.recipes()

}

object background inherits Visual {

	var property image = null

	override method sePuedeAgarrar() = false

}

class NivelDeBoton {

	var nivel
	var property selected = false
	var property position = null

	method image() {
		return "NIVEL" + nivel.numeroDeNivel() + self.textoSeleccionado() + ".png"
	}

	method numeroDeNivel() = nivel.numeroDeNivel()

	method textoSeleccionado() = if (menu.botonSeleccionado().numeroDeNivel() == nivel.numeroDeNivel()) "H" else "" // no se porq pero no funciona comparar por identidad

	method empezarNivel() {
		playScreen.caracteristicasDelNivel(nivel)
		menu.caracteristicasDeLaPantalla()
		administradorDePantalla.cambiarPantalla(playScreen)
	}

}

class Pantalla {

	method show()

	method indicarTeclas()

	method background()

	method backgroundMusic()

}

class Image {

	var property name
	var property position = null

	method image() = name + ".png"

}

object menu inherits Pantalla {

	var personaje1 = 0
	var personaje2 = 1
	var property person1 = new Image(name = "penny")
	var property person2 = new Image(name = "paulo")
	var botonSeleccionadoNumber = 0

	override method background() = "menu_background.png"

	override method backgroundMusic() = "backgroundMusic-menu-short.mp3"

	method botonSeleccionado() = self.buttons().get(botonSeleccionadoNumber)

	override method indicarTeclas() {
		keyboard.backspace().onPressDo{ game.stop()}
		keyboard.enter().onPressDo{ self.botonSeleccionado().empezarNivel()}
			// nivels
		keyboard.down().onPressDo{ self.selectChange(1)}
		keyboard.s().onPressDo{ self.selectChange(1)}
		keyboard.up().onPressDo{ self.selectChange(-1)}
		keyboard.w().onPressDo{ self.selectChange(-1)}
			// characters
		keyboard.a().onPressDo{ self.person1SelectChange(-1)}
		keyboard.d().onPressDo{ self.person1SelectChange(1)}
		keyboard.left().onPressDo{ self.person2SelectChange(-1)}
		keyboard.right().onPressDo{ self.person2SelectChange(1)}
	}

	method caracteristicasDeLaPantalla() {
		playScreen.person1(person1.name())
		playScreen.person2(person2.name())
	}

	method circularNumberScroll(number, limit) {
		return number.rem(limit).abs()
	}

	method person1SelectChange(delta) {
		personaje1 = self.circularNumberScroll(personaje1 + delta, self.nombresDePersonajes().size())
		person1.name(self.nombresDePersonajes().get(personaje1))
	}

	method person2SelectChange(delta) {
		personaje2 = self.circularNumberScroll(personaje2 + delta, self.nombresDePersonajes().size())
		person2.name(self.nombresDePersonajes().get(personaje2))
	}

	method limitBetweenListSize(list, number) {
		return number.limitBetween(0, list.size() - 1)
	}

	method nombresDePersonajes() = [ "penny", "paulo" ]

	method selectChange(delta) {
		botonSeleccionadoNumber = self.limitBetweenListSize(self.buttons(), botonSeleccionadoNumber + delta)
	}

	method buttons() {
		return [ new NivelDeBoton(nivel = nivel1), new NivelDeBoton(nivel = nivel2) ]
	}

	override method show() {
		game.addVisual(new Image(name = "title", position = game.center().left(5).up(0)))
		var nextPosition = game.center().left(3).down(5)
		self.buttons().forEach({ button =>
			button.position(nextPosition)
			game.addVisual(button)
			nextPosition = nextPosition.down(2)
		})
		self.showPickPlayer(game.at(2, game.height() / 2), person1, "pick-player1")
		self.showPickPlayer(game.at(game.width() - 9, game.height() / 2), person2, "pick-player2")
	}

	method showPickPlayer(characterPosition, character, pickPlayerImageName) {
		character.position(characterPosition)
		game.addVisual(character)
		game.addVisual(new Image(name = pickPlayerImageName, position = characterPosition.down(2).left(1)))
	}

}

object playScreen inherits Pantalla {

	var property person1 = null
	var property person2 = null
	var property caracteristicasDelNivel = nivel1
	var player1 = new Player()
	var player2 = new Player()

	override method show() {
		caracteristicasDelNivel.nivelVisualObjects().forEach({ nivelObject => game.addVisual(nivelObject)})
		self.start()
		player1.position(game.center().right(5))
		player2.position(game.center().left(5))
		game.addVisual(status)
		game.addVisual(player1)
		game.addVisual(player2)
	}

	override method backgroundMusic() = "backgroundMusic-nivel" + caracteristicasDelNivel.numeroDeNivel() + ".mp3"

	method numeroDeNivel() = caracteristicasDelNivel.numeroDeNivel()

	method recipes() = caracteristicasDelNivel.posibleRecipes()

	method addNDesks(basePosition, n, direction) {
		var desks = []
		n.times({ i => desks.add(new Desk(position = direction.move(basePosition, i - 1)))})
		return desks
	}

	method start() {
		player1.itemAgarrado(noItem)
		player2.itemAgarrado(noItem)
		player1.character(person1)
		player2.character(person2)
		status.start() // I shall not forget to keep this line when I implement the layout parser
		var timer = new Timer(totalTime = caracteristicasDelNivel.nivelLength(), frecuency = 1, user = self)
		var clockPosition = game.at(administradorDelJuego.centerX() - 1, administradorDelJuego.height() - 1)
		numberDisplayGenerator.generateDigits(caracteristicasDelNivel.nivelLength() / 1000, timer, clockPosition)
		timer.start()
	}

	method timerFinishedAction() {
		const score = new Score()
		score.setStars(caracteristicasDelNivel.starScores())
		administradorDePantalla.cambiarPantalla(score) // score could be a wko
	}

	override method background() = "piso.jpg"

	override method indicarTeclas() {
		// PLAYER 1
		keyboard.w().onPressDo{ player1.move(up)}
		keyboard.a().onPressDo{ player1.move(left)}
		keyboard.s().onPressDo{ player1.move(down)}
		keyboard.d().onPressDo{ player1.move(right)}
		keyboard.shift().onPressDo{ player1.accion()}
		keyboard.control().onPressDo{ player1.hacer()}
			// PLAYER 2
		keyboard.up().onPressDo{ player2.move(up)}
		keyboard.left().onPressDo{ player2.move(left)}
		keyboard.down().onPressDo{ player2.move(down)}
		keyboard.right().onPressDo{ player2.move(right)}
		keyboard.n().onPressDo{ player2.accion()}
		keyboard.m().onPressDo{ player2.hacer()}
	}

}

class CaracteristicasDelNivel {

	method addNDesks(basePosition, n, direction) {
		var desks = []
		n.times({ i => desks.add(new Desk(position = direction.move(basePosition, i - 1)))})
		return desks
	}

}

object nivel2 inherits CaracteristicasDelNivel {

	method numeroDeNivel() = 2

	method nivelVisualObjects() {
		const middleCurvex1 = 9
		const middleCurvex2 = middleCurvex1 + 4
		const middleSectionHeightdown = 6
		const middleSectionHeightUp = middleSectionHeightdown - 1
		const nivelObjects = [ // desks
		self.addNDesks(game.origin(), 6, up), self.addNDesks(game.at(0, game.height() - 1), 4,down), self.addNDesks(game.at(1, game.height() - 1), 9, right), self.addNDesks(game.at(1, 0), 1, right), self.addNDesks(game.at(3, 0), 7, right), // weird middle part
		self.addNDesks(game.at(middleCurvex1, 1), middleSectionHeightdown, up), self.addNDesks(game.at(middleCurvex1, game.height() - 2), middleSectionHeightUp, down), self.addNDesks(game.at(middleCurvex1 + 1, middleSectionHeightdown), middleCurvex2 - middleCurvex1 - 1, right), self.addNDesks(game.at(middleCurvex1 + 1, game.height() - 1 - middleSectionHeightUp), middleCurvex2 - middleCurvex1 - 1, right), self.addNDesks(game.at(middleCurvex2, middleSectionHeightdown), middleSectionHeightdown + 1, down), self.addNDesks(game.at(middleCurvex2, game.height() - 1), middleSectionHeightUp + 1, down), // end of weird middle part
		self.addNDesks(game.at(middleCurvex2, game.height() - 1), 5, right), self.addNDesks(game.at(middleCurvex2 + 6, game.height() - 1), 3, right), self.addNDesks(game.at(middleCurvex2 + 1, 0), 2, right), self.addNDesks(game.at(middleCurvex2 + 5, 0), 4, right), self.addNDesks(administradorDelJuego.esquinaSuperiorDerecha().down(1), 3, down), self.addNDesks(administradorDelJuego.esquinaInferiorDerecha().up(1), 8, up) ]
		nivelObjects.add([ new DeliverSpot(position = game.at(administradorDelJuego.width() - 1, 9)), new ChoppingDesk(position = game.at(middleCurvex2 + 3, 0)), new ChoppingDesk(position = game.at(middleCurvex2 + 4, 0)), new Trash(position = game.at(middleCurvex2 + 5, game.height() - 1)), new Spawner(toSpawnIngredient = new Ingredient(name = "tomato", position = game.at(0, 6))), new Spawner(toSpawnIngredient = new Ingredient(name = "lettuce", position = game.at(0, 7))), new Spawner(toSpawnIngredient = new Ingredient(name = "meat", position = game.at(0, 8))), new Spawner(toSpawnIngredient = new Ingredient(name = "potato", position = game.at(0, 9))), new Spawner(toSpawnIngredient = new Plate(position = game.at(2, 0))), new Plate(position=game.at(3,0)), new Plate(position=game.at(4,0)) ])
		return nivelObjects.flatten()
	}

	method starScores() = [ 50, 100, 200 ]

	method posibleRecipes() {
		const choppedTomato = new Ingredient(name = "tomato", state = chopped)
		const tomatoSalad = new Recipe(ingredients = [ choppedTomato, new Ingredient(name="tomato",state=chopped) ])
		const salad = new Recipe(ingredients = [ choppedTomato, new Ingredient(name="lettuce",state=chopped) ])
		const potatoSalad = new Recipe(ingredients = [ choppedTomato, new Ingredient(name="lettuce",state=chopped), new Ingredient(name="potato",state=chopped) ])
		const meatAndPotato = new Recipe(ingredients = [ new Ingredient(name="potato",state=chopped), new Ingredient(name="meat",state=chopped) ])
		return [ tomatoSalad, salad, potatoSalad, meatAndPotato ]
	}

	method nivelLength() = 180000

}

object nivel1 inherits CaracteristicasDelNivel {

	method numeroDeNivel() = 1

	method nivelVisualObjects() {
		var desks = [ self.addNDesks(game.origin(),6,up), self.addNDesks(game.origin().up(7),administradorDelJuego.height()-7,up), self.addNDesks(administradorDelJuego.esquinaSuperiorDerecha(),administradorDelJuego.width()-2,left), self.addNDesks(game.at(administradorDelJuego.centerX(),administradorDelJuego.height()-2),administradorDelJuego.height()-2,down), self.addNDesks(game.origin().right(1),2,right), self.addNDesks(administradorDelJuego.esquinaSuperiorDerecha().down(1),game.height()-1-5,down), self.addNDesks(administradorDelJuego.esquinaInferiorDerecha(), 4, up), self.addNDesks(game.origin().right(4),3,right), self.addNDesks(game.origin().right(8),administradorDelJuego.width()-12,right), self.addNDesks(administradorDelJuego.esquinaInferiorDerecha().left(1),2,left) ]
		var stuff = [ new DeliverSpot(facing=left,position=game.origin().up(6)), new Trash(position=game.at(1,administradorDelJuego.height()-1)), new Spawner(toSpawnIngredient = new Ingredient(name="meat",state=fresh,position=administradorDelJuego.esquinaInferiorDerecha().left(3))), new Spawner(toSpawnIngredient = new Ingredient(name="potato",state=fresh,position=game.origin().right(3))), new ChoppingDesk(position=administradorDelJuego.esquinaInferiorDerecha().up(4)), new Spawner(toSpawnIngredient = new Plate(position = game.origin().right(7))) ]
		var allObjects = desks.flatten()
		allObjects.addAll(stuff)
		return allObjects
	}

	method starScores() = [ 10, 40, 100 ]

	method posibleRecipes() {
		const potato = new Ingredient(name = "potato", state = fresh)
		var papas = new Recipe(ingredients = [ potato, new Ingredient(name="potato",state=chopped) ])
		var carneConPapas = new Recipe(ingredients = [ new Ingredient(name="meat",state=fresh), potato ])
		return [ papas, carneConPapas ]
	}

	method nivelLength() = 60000

}

class Score inherits Pantalla {

	var stars = [ new Star(basePosition = self.starPosition(), xOffset=0), new Star(basePosition = self.starPosition(), xOffset=1), new Star(basePosition = self.starPosition(), xOffset=2) ]

	override method indicarTeclas() {
		keyboard.enter().onPressDo({ administradorDePantalla.cambiarPantalla(menu)})
	}

	override method show() {
		numberDisplayGenerator.generateDigits(status.score(), status, game.center().up(2))
		stars.forEach({ star => game.addVisual(star)})
	}

	override method background() = "menu_background.png"

	method setStars(starScores) {
		stars.forEach({ star => star.numberList(starScores)})
	}

	override method backgroundMusic() = "backgroundMusic-menu-short.mp3"
	
	method starPosition() = game.center().left(8).down(4)

}

class Star {

	var numberProvider = status
	var property numberList = null
	var xOffset
	var basePosition

	method position() {
		return basePosition.right(6 * xOffset)
	}

	method fillingStatus() {
		return if (numberList.get(xOffset) > numberProvider.starNumber()) "empty" else "full"
	}

	method image() = self.fillingStatus() + "-star.png"

}
