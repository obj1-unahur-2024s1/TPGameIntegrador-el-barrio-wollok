import wollok.game.*
import overcooked.*


class Timer{
	var totalTime //ms
	var frecuency //hz
	var property user
	var property tickCounter = 0
	
	method tickSpacing()=1000/frecuency //ms
	
	method remainingTime()=totalTime-self.tickSpacing()*tickCounter //ms
	
	method start(){
		game.onTick(1000/frecuency, self.identity().toString(), {self.onTick()})
	}
	
	method clone(){
		return new Timer(totalTime=totalTime,frecuency=frecuency,user=user,tickCounter=tickCounter)
	}
	
	method onTick(){
		if(self.remainingTime()<=0) {
			self.stop()
			user.timerFinishedAction()
		}
		tickCounter+=1
	} 
	
	 
	
	method stop(){
		game.removeTickEvent(self.identity().toString())
	}
	
	method getProgressBar(amountOfImages,recipe){
		return new ProgressBar(amountOfImages=amountOfImages,totalTime=totalTime,timer=self)
	}
	
//	method getClock(position){
//		return new Clock(timer=self,position=position)
//	}
	
	
	
	method showingNumber()=(self.remainingTime()/1000).truncate(0)
	
}

class ProgressBar inherits Visual{
	var property totalTime
	var amountOfImages
	var timer
		
	override method isPickable()=false
	
	method start(){
		timer.start()
	}
	
	method imageNumber(){		
		var timeBetweenImages = totalTime/amountOfImages
		var decimalImageNumber= timer.remainingTime()/timeBetweenImages
		return (decimalImageNumber.truncate(0) - 1 ).max(0)
	}
	override method image() = "progress" + self.imageNumber() +".png"
	
}


class Digit inherits Visual{
	var digitPosition
	var numberProvider
	var basePosition
	override method position()=basePosition.right(digitPosition)
	method correspondingDigit(){
		const numberAsString = numberProvider.showingNumber().toString()
		return if (numberAsString.size() - 1 < digitPosition)
			"noNumber"
		else
			numberAsString.charAt(digitPosition)
	}
	override method image() = "numbers/"+self.correspondingDigit()+".png"
	override method isPickable()=false
	override method canContain(item)=false
}

object numberDisplayGenerator{
	method generateDigits(maximumNumber,numberProvider,position){
		var amountOfDigitsForClock=maximumNumber.toString().size()
		amountOfDigitsForClock.times({i=>game.addVisual(new Digit(digitPosition=i-1,numberProvider=numberProvider,basePosition=position))})
	}
}