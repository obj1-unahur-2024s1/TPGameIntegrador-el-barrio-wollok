import wollok.game.*
import items.*
import soundProducer.*

object administradorDelJuego {

	// Todo: lista jugadores
	var property height = 14
	var property width = 22 

	method posicionLimiteEntre(aPosition) {
		return aPosition.x() >= 0 && aPosition.x() < width && aPosition.y() >= 0 && aPosition.y() < height
	}

	method esquinaSuperiorDerecha() {
		return game.at(width - 1, height - 1)
	}
	
	method esquinaInferiorDerecha(){
		return game.at(width-1,0)
	}

	method centerY() = height / 2

	method centerX() = width / 2
	
	method center()=game.at(self.centerX(),self.centerY())

}

class Visual {

	var position = game.origin() // algunas subclases no usan este atributo

	method position() = position

	method position(newPosition) {
		position = newPosition
	}
	
	method puedeHacerAlgo()=false

	method sePuedeAgarrar()

	method image()

	method puedeCaminar() = true

	method move(direction, n) {
		position = direction.move(position, n)
	}

	method puedeContener(item) = true

	method ponerEncima(item) {
	}

	method hacer(somePlayer) {
	}

	method puedeInteractuar() = true

	method interactuar(somePlayer) {
	}

}

//Jugadores
class Player inherits Visual {

	var property character = null
	var property facingDirection = up
	var property itemAgarrado = noItem

	// compartamiento basicos

	override method puedeCaminar() = false

	override method image() = character + "_" + facingDirection.text() + ".png"

	override method puedeContener(item) = false
	

	// movimiento
	method move(direccion) {
		var sigPosicion= direccion.move(position, 1) // position=original position
		if (self.positionIspuedeCaminar(sigPosicion)) {
			self.move(direccion, 1)
		}
		self.direccionDeLaCara(direccion)
		self.refresh()
	}


	method moveN(direction, n) {
		n.times({ x => self.move(direction)})
	}

	method direccionDeLaCara(direction) {
		facingDirection = direction
	}

	method refresh() {
		game.removeVisual(self)
		game.addVisual(self)
	}

	// agarrar /dejar
	method accion() {itemAgarrado.accion(self)}
	
	method agarrar(item) {
		soundProducer.sound("sounds/agarrar.mp3").play()
		item.owner(self)
		if(item.esComida())item.refreshImage()
		itemAgarrado = item
	}

	method dejar() {
		if(!self.elementosFrontales().all({elem=>!elem.puedeContener(itemAgarrado)})){
			itemAgarrado.owner(null)
			itemAgarrado.position(self.posicionDeItem())
			var frontContainersForItem = game.colliders(itemAgarrado).filter({ elem => elem.puedeContener(itemAgarrado)})
			if (frontContainersForItem.isEmpty().negate()) frontContainersForItem.last().ponerEncima(itemAgarrado)
			itemAgarrado = noItem
			const sonidoDejarComida = soundProducer.sound("sounds/dejar.mp3")
			sonidoDejarComida.volume(0.5)
			sonidoDejarComida.play()			
		}
	}
	method estaAgarrando(item) {
		return itemAgarrado == item
	}
	
	method elementosFrontales() = facingDirection.move(position, 1).allElements()

	method elementosFrontalesAplicados(criteria)=self.elementosFrontales().filter(criteria)


	override method sePuedeAgarrar() = false
	
	method posicionDeItem() = facingDirection.move(position, 1)
		
	

	// interaccion
	method interaccionDelFrente() {
		const elementosInteractivosDelFrente=self.elementosFrontalesAplicados({ elem => elem.puedeInteractuar()})
		if (elementosInteractivosDelFrente.isEmpty().negate()) elementosInteractivosDelFrente.last().interactuar(self) 
	}

	method hayAlgoAdelante() = !self.elementosFrontales().isEmpty()

	// hacer
	method hacer() {
		const dobleElementosFrontales = self.elementosFrontales().filter({elem=>elem.puedeHacerAlgo()})
		if (!dobleElementosFrontales.isEmpty()) dobleElementosFrontales.last().hacer(self) // maybe this should be a forEach or first()
	}

	// metodos que deberian ser de posicion pero no se como hacerlo
	method positionIspuedeCaminar(aPosition) {
		return aPosition.allElements().all({ element => element.puedeCaminar() }) && administradorDelJuego.posicionLimiteEntre(aPosition)
	}

}

//Direcciones
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

