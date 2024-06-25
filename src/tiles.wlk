import items.*
import overcooked.*
import wollok.game.*
import statusBar.*
import soundProducer.*

class Tile inherits Visual {

	override method sePuedeAgarrar() = false

	override method puedeCaminar() = false

}

class DeliverSpot inherits Tile {
	
	var facing = right

	override method image() = "exit-" + facing.text()+".png"

	override method puedeContener(item) = item.puedeEntregarse() &&
											  status.recipes().any({ recipe => recipe.plateMeetsRequierements(item)})

	override method ponerEncima(item) {
		self.deliver(item)
	}

	method deliver(plate) {
//		console.println("Delivered " + plate)
		var recipe = status.recipes().find({ recipe => recipe.plateMeetsRequierements(plate) })
		status.recipeDelivered(recipe)
		plate.delivered()
	}

}

class Trash inherits Tile{
	override method image()="basura.png"
	
	override method ponerEncima(item){
		item.trash()
	}
}

class Desk inherits Tile {

	override method image() = "desk.png"

	override method puedeContener(item) = true

	override method ponerEncima(item) {
	}

}

class Spawner inherits Tile {

	var toSpawnIngredient

	override method position() = toSpawnIngredient.position()

	override method puedeContener(item) = false

	override method interactuar(somePlayer) {
		var clonedIngredient = toSpawnIngredient.clone()
//		clonedIngridient.position(self.position())
		game.addVisual(clonedIngredient)
		somePlayer.agarrar(clonedIngredient)
	}

	override method image() = toSpawnIngredient.spawnerImage()

}

//cooking tiles
class ChoppingDesk inherits Tile {

	var placedIngredient = noItem
	var cuttingProgress = 0

	override method image() = "cuttingDesk.png"

	override method hacer (somePlayer) {
		if (placedIngredient != noItem) self.chop()
	}

	method chop() {
		soundProducer.sound("sounds/chop.mp3").play()
		cuttingProgress += 15.randomUpTo(26).truncate(0) //so that the player doesnt know how many chops it takes
		if (cuttingProgress >= 100) {//No se si el jugador deberia tener responsabilidad de esto
			placedIngredient.chop()
			cuttingProgress = 0		
			placedIngredient=noItem		
		}
	}
	
	override method puedeHacerAlgo()=true

	override method puedeContener(item) = item.esComida()&& item.choppable()&& placedIngredient == noItem

	override method ponerEncima(item) {
			placedIngredient = item
	}

}

