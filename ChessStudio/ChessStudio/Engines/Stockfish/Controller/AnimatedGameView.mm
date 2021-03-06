/*
 Stockfish, a chess program for iOS.
 Copyright (C) 2004-2013 Tord Romstad, Marco Costalba, Joona Kiiski.
 
 Stockfish is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 Stockfish is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#import "AnimatedGameView.h"
#import "Game.h"
#import "SettingManager.h"


@interface AnimatedGameView() {

    CGFloat animationDuration;
    SettingManager *settingManager;
    
    //UIColor *darkSquareColor, *lightSquareColor;

}

//@property (nonatomic, strong) UIImage *darkSquareImage;
//@property (nonatomic, strong) UIImage *lightSquareImage;

- (void)removePieceOn:(int)square;
- (void)putPiece:(int)piece onSquare:(int)square;
- (void)restartMoveAnimation:(id)object;
- (void)clearBoard;
- (void)setUpBoard;

@end

@implementation AnimatedGameView


- (id)initWithGame:(Game *)g frame:(CGRect)rect {
   if (self = [super initWithFrame: rect]) {
      game = [g retain];
      [game toBeginning];
      sqSize = rect.size.width / 8;
       
       settingManager = [SettingManager sharedSettingManager];
       
       //_darkSquareImage = [settingManager getDarkSquare];
       //_lightSquareImage = [settingManager getLightSquare];
       
       //darkSquareColor = [UIColor blackColor];
       //lightSquareColor = [UIColor whiteColor];
       
      //darkSquareImage = [[UIImage imageNamed: @"DarkNewspaper96.png"] retain];
      //lightSquareImage = [[UIImage imageNamed: @"LightNewspaper96.png"] retain];
       //darkSquareImage = [[UIImage imageNamed: @"BlackWood3.png"] retain];
       //lightSquareImage = [[UIImage imageNamed: @"WhiteWood3.png"] retain];
       /*
      static NSString *pieceImageNames[16] = {
         nil, @"WPawn", @"WKnight", @"WBishop", @"WRook", @"WQueen", @"WKing", nil,
         nil, @"BPawn", @"BKnight", @"BBishop", @"BRook", @"BQueen", @"BKing", nil
      };
      */
       static NSString *pieceImageNames[16] = {
           nil, @"wp", @"wn", @"wb", @"wr", @"wq", @"wk", nil,
           nil, @"bp", @"bn", @"bb", @"br", @"bq", @"bk", nil
       };
       
      //NSString *pieceSet = @"USCF";
      //NSString *pieceSet = @"lin96";
      // NSString *pieceSet = [def objectForKey:@"pieces"];
       NSString *pieceSet = [settingManager getPieceTypeToLoad];
       for (Piece p = WP; p <= BK; p++) {
         if (piece_is_ok(p)) {
            pieceImages[p] =
               [[UIImage imageNamed: [NSString stringWithFormat: @"%@%@.png", pieceSet, pieceImageNames[p]]] retain];
         }
         else
            pieceImages[p] = nil;
      }
      [self setUpBoard];
       
       animationDuration = 0.30;
       animationShouldStop = YES;
       
       
       //[self setBackgroundColor:[UIColor colorWithRed:255.0 green:199.0 blue:24.0 alpha:1.0]];
   }
   return self;
}


- (void)drawRect:(CGRect)rect {
    darkSquareImage = [settingManager getDarkSquare];
    lightSquareImage = [settingManager getLightSquare];
   for (int i = 0; i < 8; i++)
      for (int j = 0; j < 8; j++) {
          CGRect r = CGRectMake(i * sqSize, j*sqSize, sqSize, sqSize);
          if (darkSquareImage && lightSquareImage) {
              [(((i + j) & 1)? darkSquareImage : lightSquareImage) drawInRect: r];
          }
          else {
              //[(((i + j) & 1)? darkSquareColor : lightSquareColor) set];
              //UIRectFill(CGRectMake(i*sqSize, j*sqSize, sqSize, sqSize));
          }
         //CGRect r = CGRectMake(i * sqSize, j * sqSize, sqSize, sqSize);
         //[(((i + j) & 1)? darkSquareImage : lightSquareImage) drawInRect: r];
      }
}


- (void)clearBoard {
   for (Square s = SQ_A1; s <= SQ_H8; s++)
      [self removePieceOn: (int)s];
}


- (void)setUpBoard {
   for (Square s = SQ_A1; s <= SQ_H8; s++) {
      if ([game pieceOn: s] == EMPTY)
         pieceViews[s] = nil;
      else {
         int f = int(square_file(s)), r = int(square_rank(s));
         pieceViews[s] = [[UIImageView alloc] initWithImage: pieceImages[[game pieceOn: s]]];
         [pieceViews[s] setFrame: CGRectMake(f*sqSize, (7-r)*sqSize, sqSize, sqSize)];
         [self addSubview: pieceViews[s]];
         [pieceViews[s] release];
      }
   }
}


- (void)moveAnimationFinished:(NSString *)animationID
                     finished:(BOOL)finished
                      context:(void *)context {
   if (animationShouldStop)
      return;
   else if ([game atEnd])
      [self performSelector: @selector(restartMoveAnimation:)
                 withObject: nil afterDelay: 2.0];
   else {
      Move m = [[game nextMove] move];
      int from = int(move_from(m)), to = int(move_to(m));
      static const int woo = 1, wooo = 2, boo = 3, booo = 4;
      int castle = 0;
      
      // Adjust destination square for castling
      if (move_is_short_castle(m)) {
         castle = ([game sideToMove] == WHITE)? woo : boo;
         to = ([game sideToMove] == WHITE)? int(SQ_G1) : int(SQ_G8);
      } else if (move_is_long_castle(m)) {
         castle = ([game sideToMove] == WHITE)? wooo : booo;
         to = ([game sideToMove] == WHITE)? int(SQ_C1) : int(SQ_C8);
      }
      
      UIImageView *v = pieceViews[from];
      CGContextRef context = UIGraphicsGetCurrentContext();
      [UIView beginAnimations: nil context: context];
      [UIView setAnimationDelegate: self];
      [UIView setAnimationDidStopSelector:
       @selector(moveAnimationFinished:finished:context:)];
      [UIView setAnimationCurve: UIViewAnimationCurveLinear];
      //[UIView setAnimationDuration: 0.15];
       [UIView setAnimationDuration:animationDuration];
      // In the case of a capture, remove the captured piece.
      if ([game pieceOn: Square(to)] != EMPTY) [self removePieceOn: to];
      else if (move_is_ep(m))
         [self removePieceOn: Square(to) - pawn_push([game sideToMove])];

      // Move the piece
      int f = to % 8, r = to / 8;
      [v setFrame: CGRectMake(f * sqSize, (7 - r) * sqSize, sqSize, sqSize)];
      pieceViews[to] = v;
      pieceViews[from] = nil;
      
      // Replace the piece image in case of a promotion
      if (move_promotion(m))
         [v setImage: pieceImages[piece_of_color_and_type([game sideToMove], move_promotion(m))]];
      
      // If move is a castle, move the rook
      if (castle) {
         if (castle == woo) from = int(SQ_H1), to = int(SQ_F1);
         else if (castle == wooo) from = int(SQ_A1), to = int(SQ_D1);
         else if (castle == boo) from = int(SQ_H8), to = int(SQ_F8);
         else if (castle == booo) from = int(SQ_A8), to = int(SQ_D8);
         v = pieceViews[from];
         f = to % 8, r = to / 8;
         [v setFrame: CGRectMake(f * sqSize, (7 - r) * sqSize, sqSize, sqSize)];
         pieceViews[to] = v;
         pieceViews[from] = nil;
      }
      
      // Do the move on the internal board
      [game stepForward];
      
      [UIView commitAnimations];
   }
}


- (void)startAnimation {
    if (animationShouldStop == NO) {
        return;
    }
    animationShouldStop = NO;
   [self moveAnimationFinished: nil finished: NO context: 0];
}


- (void)stopAnimation {
   animationShouldStop = YES;
}

- (void) accelera {
    animationDuration -= 0.1;
    if (animationDuration<0.1) {
        animationDuration = 0.1;
    }
}

- (void) rallenta {
    animationDuration += 0.1;
}

- (void)restartMoveAnimation: (id)object {
    animationShouldStop = YES;
   [game toBeginning];
   [self clearBoard];
   [self setUpBoard];
   [self startAnimation];
}

- (void)removePieceOn:(int)square {
   [pieceViews[square] removeFromSuperview];
   pieceViews[square] = nil;
}


- (void)putPiece:(int)piece onSquare:(int)square {
   int f = square % 8, r = square / 8;
   pieceViews[square] = [[UIImageView alloc] initWithImage: pieceImages[piece]];
   [pieceViews[square] setFrame: CGRectMake(f*sqSize, (7-r)*sqSize, sqSize, sqSize)];
   [self addSubview: pieceViews[square]];
   [pieceViews[square] release];
}

- (void)dealloc {
   NSLog(@"AnimatedGameView dealloc");
   [game release];
   //[_darkSquareImage release];
   //[_lightSquareImage release];
   for (int i = 0; i < 16; i++) [pieceImages[i] release];
   [super dealloc];
}

@end
