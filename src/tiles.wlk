import items.*
import overcooked.*
import wollok.game.*
import statusBar.*
import soundProducer.*

class Tile inherits Visual {

	override method isPickable() = false

	override method walkable() = false

}

class DeliverSpot inherits Tile {
	
	var facing = right

	override method image() = "exit-" + facing.text()+".png"

	override method canContain(item) = item.canDeliver() &&
											  status.recipes().any({ recipe => recipe.plateMeetsRequierements(item)})

	override method droppedOnTop(item) {
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
	override method image()="trash.png"
	
	override method droppedOnTop(item){
		item.trash()
	}
}

class Desk inherits Tile {

	override method image() = "desk.png"

	override method canContain(item) = true

	override method droppedOnTop(item) {
	}

}

class Spawner inherits Tile {

	var toSpawnIngredient

	override method position() = toSpawnIngredient.position()

	override method canContain(item) = false

	override method interact(somePlayer) {
		var clonedIngredient = toSpawnIngredient.clone()
//		clonedIngridient.position(self.position())
		game.addVisual(clonedIngredient)
		somePlayer.pickup(clonedIngredient)
	}

	override method image() = toSpawnIngredient.spawnerImage()

}

//cooking tiles
class ChoppingDesk inherits Tile {

	var placedIngredient = noItem
	var cuttingProgress = 0

	override method image() = "cuttingDesk.png"

	override method do(somePlayer) {
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
	
	override method canDoSomething()=true

	override method canContain(item) = item.isFood()&& item.choppable()&& placedIngredient == noItem

	override method droppedOnTop(item) {
			placedIngredient = item
	}

}

