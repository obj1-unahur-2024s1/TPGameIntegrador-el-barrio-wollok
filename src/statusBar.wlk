import overcooked.*
import tiles.*
import items.*
import screens.*
import wollok.game.*
import timer.*
import soundProducer.*


object status inherits Visual {

	var property recipes = []
	var property score = 0
	var width = 3

	override method isPickable() = false

	override method image() = "status-bar.jpg"

	override method position() = game.at(gameManager.width(), 0)

	method width() = width

	method addRecipe(recipe) {//no se si quiero que toda esta logica este aca, pero este objeto es el unico que ve todo
		self.doAndRefresh({
		recipes.add(recipe)
		var newTimer=new Timer(totalTime = 90000,frecuency=2,user=recipe)
		var progBar= newTimer.getProgressBar(4,recipe)
		recipe.progressBar(progBar)
		newTimer.start()
		})
	}

	method recipeDelivered(recipe) {
		soundProducer.sound("sounds/deliver_bell.mp3").play()
		score += recipe.points()
		self.removeRecipe(recipe)
	}
	
	method doAndRefresh(toDoAction){
		self.clearVisuals()
		toDoAction.apply()
		self.show()
	}
	
	method removeRecipe(recipe){
		self.doAndRefresh({recipes.remove(recipe)})
		
	}

	method refreshVisuals() {
		self.clearVisuals()
		self.show()
	}

	method clearVisuals() {
		recipes.forEach({ recipe => recipe.clear()})
	}

	method show() {
		var recipeCount = 0
		recipes.forEach({ recipe =>
			recipe.show(recipeCount)
			recipeCount = recipeCount + 1
		})
	}

	method addRandomRecipe(levelRecipes) {
		var newRecipeProbability = 5 // %
		var randomNumber = 0.randomUpTo(100)
		if (randomNumber > newRecipeProbability) {
			var totalRecipesSize = levelRecipes.size()
			var randomRecipeIndex = 0.randomUpTo(totalRecipesSize - 1)
			self.addRecipe(levelRecipes.get(randomRecipeIndex).clone())
		}
	}

	method start() {
		recipes.clear()
		score = 0
		game.schedule(500,{self.addRandomRecipe(screenManager.recipes())}) // first recipe is instant (almost because it has to wait for the level to load)
		const newRecipeSpacing = 11000
		game.onTick(newRecipeSpacing, "random recipe", { if (recipes.size() <= 4) self.addRandomRecipe(screenManager.recipes())})
	}	
	
	method showingNumber()= score
	
	method starNumber()=score

}

class Recipe {

	var ingredients
	//	var property timer = null //timer gets assigned when recipe is added to the status bar
	var property progressBar = null//timer.getProgressBar(4,self)//number of images on bar
	method height() = 2

	method points() = ingredients.sum({ingredient => if(ingredient.specialState()) 15 else 10})

	method show(yCount) {
		var ingCount = 0
		ingredients.forEach({ ingredient =>
			ingredient.position(game.at(gameManager.width() + ingCount, self.height() * yCount))
			game.addVisual(ingredient)
			ingCount = ingCount + 1
		})
		progressBar.position(game.at(gameManager.width(),self.height()*yCount + 1))
		game.addVisual(progressBar)
	}

	method clear() {
		game.removeVisual(progressBar)
		ingredients.forEach({ ing => game.removeVisual(ing)})
	}

//	method plateMeetsRequierements(aPlate) {
//		var plateIngredientsSet = self.cloneAsSet(aPlate.ingredients())
//		var ingredientsAsSet = self.cloneAsSet(ingredients)
//		return self.sameSizeOfSet(plateIngredientsSet, ingredientsAsSet) && self.sameSizeOfSet(plateIngredientsSet.intersection(ingredientsAsSet), plateIngredientsSet)
//	}

	method plateMeetsRequierements(aPlate)=	self.sameOccurrencesOfElements(aPlate.ingredients(), ingredients) && self.sameOccurrencesOfElements(ingredients, aPlate.ingredients())
	
	
	method sameOccurrencesOfElements(listA,listB){
		return listA.all({ingredient=>
			listA.occurrencesOf(ingredient)  == listB.occurrencesOf(ingredient)
		})
		
	}
	
	method timerFinishedAction(){
//		console.println("Recipe expired")	
		status.removeRecipe(self)
	}
	method sameSizeOfSet(aSet, otherSet) = aSet.size() == otherSet.size()

	method cloneAsSet(list) = list.map({ x => x.clone() }).asSet()

	method clone() {//used for copying the recipes from the level, does not save state of the progress bar.
		return new Recipe(ingredients = self.cloneIngredients())
	}
	
	method cloneIngredients() = ingredients.map({ ing => ing.clone() })
}
