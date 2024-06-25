import wollok.game.*
import overcooked.*

class Item inherits Visual {


	var property owner= null

	override method position(){
			if(owner != null)return owner.posicionDeItem()
			else return position
	}

	method accion(somePlayer) {
		somePlayer.dejar()
	}
	
	override method sePuedeAgarrar() {
		return owner == null
	}
	
	method basura(){
		game.removeVisual(self)
	}

	method puedeEntregarse()

	method esComida() = false

	override method interactuar(somePlayer) {
		if (self.sePuedeAgarrar()) somePlayer.agarrar(self)
	}

	override method puedeContener(item) = false
	
	override method puedeCaminar()=true
	
	method refreshImage(){
		game.removeVisual(self)
		game.addVisual(self)
	}
	
	method spawnerImage()

	override method puedeInteractuar()=self.sePuedeAgarrar()
}

object noItem {

	var property owner = null

	method cut() {
	}
	
	method name()="noItem"

	method move(no, importa) {
	}

	method sePuedeAgarrar() = true

	method accion(somePlayer) {
		somePlayer.interaccionDelFrente()
	}
	
	method puedeInteractuar()=false
	
	method puedeEntregarse()=false

	method position(noimporta) {
	}

	method puedeContener(item) = true

	method esComida() = false

}

class Ingredient inherits Item {

	var property name
	var property state = fresh
	var property suffixIndex=0
	const suffixList= ["", "-topleft","-topright","-bottomright","-bottomleft"]

	method clone() = new Ingredient(name = name, owner = owner, position = self.position(), state = state)

	override method puedeEntregarse()=false

	override method esComida() = true
	
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

	override method puedeContener(item) = item.esComida()

	override method image() = "plate.png"

	method addIngredient(food) {
		food.refreshImage()
		ingredients.add(food)
		food.suffixIndex(ingredients.size())
		food.owner(self)
	}

	override method basura(){
		super()
		ingredients.forEach({ing=>game.removeVisual(ing)})
	}

	override method ponerEncima(item) {
		if (item.esComida()) self.addIngredient(item)
	}	
	
	method delivered(){
		ingredients.forEach({ing=>game.removeVisual(ing)})
		game.removeVisual(self)
	}
	
	override method puedeEntregarse()= true
	
	method clone() = new Plate(ingredients=[],position=position)

	override method spawnerImage() = "plate-spawner.png"

	method posicionDeItem()=self.position()
}

