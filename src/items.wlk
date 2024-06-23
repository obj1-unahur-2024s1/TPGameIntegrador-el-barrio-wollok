import wollok.game.*
import overcooked.*

class Item inherits Visual {


	var property owner= null

	override method position(){
			if(owner != null)return owner.itemPosition()
			else return position
	}

	method action(somePlayer) {
		somePlayer.drop()
	}
	
	override method isPickable() {
		return owner == null
	}
	
	method trash(){
		game.removeVisual(self)
	}

	method canDeliver()

	method isFood() = false

	override method interact(somePlayer) {
		if (self.isPickable()) somePlayer.pickup(self)
	}

	override method canContain(item) = false
	
	override method walkable()=true
	
	method refreshImage(){
		game.removeVisual(self)
		game.addVisual(self)
	}
	
	method spawnerImage()

	override method canInteract()=self.isPickable()
}

object noItem {

	var property owner = null

	method cut() {
	}
	
	method name()="noItem"

	method move(no, importa) {
	}

	method isPickable() = true

	method action(somePlayer) {
		somePlayer.interactWithFront()
	}
	
	method canInteract()=false
	
	method canDeliver()=false

	method position(noimporta) {
	}

	method canContain(item) = true

	method isFood() = false

}

class Ingredient inherits Item {

	var property name
	var property state = fresh
	var property suffixIndex=0
	const suffixList= ["", "-topleft","-topright","-bottomright","-bottomleft"]

	method clone() = new Ingredient(name = name, owner = owner, position = self.position(), state = state)

	override method canDeliver()=false

	override method isFood() = true
	
	method specialState() = state !== fresh

	override method image() =name + state.name()+self.miniatureSuffix() + ".png"

	method miniatureSuffix(){
	 	return suffixList.get(suffixIndex.min(suffixList.size()-1))
	}	
	

	override method equals(otherIngredient) {
		return name == otherIngredient.name() && state == otherIngredient.state()
	}
	
	override method ==(otherIngredient){
		return self.equals(otherIngredient)
	}

	method choppable()=state.choppable()

	override method spawnerImage() = name + "-spawner.png"

	method chop() {
		state = chopped
	}
}
//State objects
object fresh{
	method name()=""
	method choppable() = true
}

object chopped{
	method name()="-chopped"
	method choppable()=false
}

//var meat = new Ingredient(name="meat")
//
//var lettuce = new Ingredient (name="lettuce")
//
//var tomato =  new Ingredient (name="tomato")
class Plate inherits Item {

	var property ingredients = []

	override method canContain(item) = item.isFood()

	override method image() = "plate.png"

	method addIngredient(food) {
		food.refreshImage()
		ingredients.add(food)
		food.suffixIndex(ingredients.size())
		food.owner(self)
	}

	override method trash(){
		super()
		ingredients.forEach({ing=>game.removeVisual(ing)})
	}

	override method droppedOnTop(item) {
		if (item.isFood()) self.addIngredient(item)
	}	
	
	method delivered(){
		ingredients.forEach({ing=>game.removeVisual(ing)})
		game.removeVisual(self)
	}
	
	override method canDeliver()= true
	
	method clone() = new Plate(ingredients=[],position=position)

	override method spawnerImage() = "plate-spawner.png"

	method itemPosition()=self.position()
}

