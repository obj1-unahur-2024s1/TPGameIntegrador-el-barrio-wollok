import wollok.game.*
import items.*
import soundProducer.*

object gameManager {

	// ToDo: lista jugadores
	var property height = 14
	var property width = 22 // values suited for a 1280x720 screen

	method positionIsBetweenBounds(aPosition) {
		return aPosition.x() >= 0 && aPosition.x() < width && aPosition.y() >= 0 && aPosition.y() < height
	}

	method upperRightCorner() {
		return game.at(width - 1, height - 1)
	}
	
	method bottomRightCorner(){
		return game.at(width-1,0)
	}

	method centerY() = height / 2

	method centerX() = width / 2
	
	method center()=game.at(self.centerX(),self.centerY())

}

class Visual {

	var position = game.origin() // there are subclasses that don't use this atribute

	method position() = position

	method position(newPosition) {
		position = newPosition
	}
	
	method canDoSomething()=false

	method isPickable()

	method image()

	method walkable() = true

	method move(direction, n) {
		position = direction.move(position, n)
	}

	method canContain(item) = true

	method droppedOnTop(item) {
	}

	method do(somePlayer) {
	}

	method canInteract() = true

	method interact(somePlayer) {
	}

}

//Jugadores
class Player inherits Visual {

	var property character = null
	var property facingDirection = up
	var property carriedItem = noItem

	// basic behaviour

	override method walkable() = false

	override method image() = character + "_" + facingDirection.text() + ".png"

	override method canContain(item) = false
	

	// movement
	method move(direction) {
		var nextPosition = direction.move(position, 1) // position=original position
		if (self.positionIsWalkable(nextPosition)) {
			self.move(direction, 1)
		}
		self.faceTowards(direction)
		self.refresh()
	}


	method moveN(direction, n) {
		n.times({ x => self.move(direction)})
	}

	method faceTowards(direction) {
		facingDirection = direction
	}

	method refresh() {
		game.removeVisual(self)
		game.addVisual(self)
	}

	// pickup/drop
	method action() {carriedItem.action(self)}
	
	method pickup(item) {
		soundProducer.sound("sounds/pickup.mp3").play()
		item.owner(self)
		if(item.isFood())item.refreshImage()
		carriedItem = item
	}

	method drop() {
		if(!self.frontElements().all({elem=>!elem.canContain(carriedItem)})){
			carriedItem.owner(null)
			carriedItem.position(self.itemPosition())
			var frontContainersForItem = game.colliders(carriedItem).filter({ elem => elem.canContain(carriedItem)})
			if (frontContainersForItem.isEmpty().negate()) frontContainersForItem.last().droppedOnTop(carriedItem)
			carriedItem = noItem
			const dropSound = soundProducer.sound("sounds/drop.mp3")
			dropSound.volume(0.5)
			dropSound.play()			
		}
	}
	method isPicking(item) {
		return carriedItem == item
	}
	
	method frontElements() = facingDirection.move(position, 1).allElements()

	method frontElementsThatApply(criteria)=self.frontElements().filter(criteria)


	override method isPickable() = false
	
	method itemPosition() = facingDirection.move(position, 1)
		
	

	// interaction
	method interactWithFront() {
		const frontInteractiveElements=self.frontElementsThatApply({ elem => elem.canInteract()})
		if (frontInteractiveElements.isEmpty().negate()) frontInteractiveElements.last().interact(self) // forEach({ x => x.interact(self)})
	}

	method hasSomethingInFront() = !self.frontElements().isEmpty()

	// do
	method do() {
		const doableFrontElements = self.frontElements().filter({elem=>elem.canDoSomething()})
		if (!doableFrontElements.isEmpty()) doableFrontElements.last().do(self) // maybe this should be a forEach or first()
	}

	// metodos que deberian ser de posicion pero no se como hacerlo
	method positionIsWalkable(aPosition) {
		return aPosition.allElements().all({ element => element.walkable() }) && gameManager.positionIsBetweenBounds(aPosition)
	}

}

//Directions
class Direction {

	method text()

	method move(position, n)

}

object up inherits Direction {

	override method text() = "up"

	override method move(position, n) = position.up(n)

}

object right inherits Direction {

	override method text() = "right"

	override method move(position, n) = position.right(n)

}

object down inherits Direction {

	override method text() = "down"

	override method move(position, n) = position.down(n)

}

object left inherits Direction {

	override method text() = "left"

	override method move(position, n) = position.left(n)

}

